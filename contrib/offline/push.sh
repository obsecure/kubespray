#!/bin/bash
set -euo pipefail  # 엄격한 오류 처리

# 변수 설정
export IMAGE_DIR="${PWD}/container-images"
export IMAGE_LIST="${IMAGE_DIR}/container-images.txt"
export DESTINATION_REGISTRY="10.0.1.6:5000"  # IP로 변경
export NERDCTL_NAMESPACE="k8s.io"
SUDO=$(id -u -ne 0 && echo "sudo" || echo "")

# 레지스트리 호스트 해석 확인
if ! ping -c 1 "${DESTINATION_REGISTRY%%:5000}" &>/dev/null; then
    echo "ERROR: Cannot resolve ${DESTINATION_REGISTRY%%:5000}"
    exit 1
fi

# IMAGE_LIST 파일 확인
if [[ ! -f "${IMAGE_LIST}" ]]; then
    echo "ERROR: ${IMAGE_LIST} does not exist"
    exit 1
fi

exit_status=0

# container-images.txt 파일 읽기
while read -r file_name raw_image; do
    # 빈 줄 또는 잘못된 형식 스킵
    if [[ -z "${file_name}" || -z "${raw_image}" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') --> Skipping empty or malformed line"
        continue
    fi

    # 파일 존재 확인
    if [[ ! -f "${IMAGE_DIR}/${file_name}" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') --> ERROR: File ${file_name} does not exist"
        exit_status=1
        continue
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') --> Loading ${file_name}"
    # 이미지 로드
    if ! loaded_output=$(${SUDO} nerdctl -n "${NERDCTL_NAMESPACE}" load -i "${IMAGE_DIR}/${file_name}"); then
        echo "$(date '+%Y-%m-%d %H:%M:%S') --> ERROR: Failed to load ${file_name}"
        exit_status=1
        continue
    fi

    # 로드된 이미지 이름 추출
    org_image=$(echo "$loaded_output" | grep -o -E "Loaded image: .*" | sed 's/Loaded image: //' | head -n 1)
    if [[ -z "${org_image}" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') --> ERROR: Failed to get image name from ${file_name}"
        exit_status=1
        continue
    fi

    new_image="${DESTINATION_REGISTRY}/${raw_image}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') --> Tagging ${org_image} as ${new_image}"
    # 이미지 태그
    if ! ${SUDO} nerdctl -n "${NERDCTL_NAMESPACE}" tag "${org_image}" "${new_image}"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') --> ERROR: Failed to tag ${org_image}"
        exit_status=1
        continue
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') --> Pushing ${new_image}"
    # 이미지 푸시
    if ! ${SUDO} nerdctl -n "${NERDCTL_NAMESPACE}" push --insecure-registry "${DESTINATION_REGISTRY}" "${new_image}"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') --> ERROR: Failed to push ${new_image}"
        exit_status=1
        continue
    fi
done < "${IMAGE_LIST}"

echo "$(date '+%Y-%m-%d %H:%M:%S') --> Image push process completed with status ${exit_status}"
exit ${exit_status}
