#!/bin/bash
# 변수 설정
export IMAGE_DIR="${PWD}/container-images"
export IMAGE_LIST="${IMAGE_DIR}/container-images.txt"
# 아래 HOSTNAME -> IP 변경해서 사용하세요
export DESTINATION_REGISTRY="jyow:5000"

# container-images.txt 파일을 읽어오면서 루프 실행
cat ${IMAGE_LIST} | while read -r line; do
    # 파일 이름과 이미지 이름 추출
    file_name=$(echo ${line} | awk '{print $1}')
    raw_image=$(echo ${line} | awk '{print $2}')
    new_image="${DESTINATION_REGISTRY}/${raw_image}"

    # 각 변수가 비어있는지 확인
    if [ -z "${file_name}" ] || [ -z "${raw_image}" ]; then
        echo "--> Skipping empty or malformed line in ${IMAGE_LIST}"
        continue
    fi

    echo "--> Loading ${file_name}"
    # nerdctl load 실행하고, 출력에서 'Loaded image:' 라인을 찾아 실제 이미지 이름을 추출 (가장 안정적인 방법)
    loaded_output=$(sudo nerdctl -n k8s.io load -i "${IMAGE_DIR}/${file_name}")
    org_image=$(echo "$loaded_output" | grep -o -E "Loaded image: .*" | sed 's/Loaded image: //')

    # 실제 로드된 이미지 이름이 있는지 확인
    if [ -z "${org_image}" ]; then
        echo "--> FAILED to get image name from load output for ${file_name}. Skipping."
        continue
    fi

    echo "--> Tagging ${org_image} as ${new_image}"
    # 실제 로드된 이미지 이름(org_image)을 소스로 사용하여 태그
    sudo nerdctl -n k8s.io tag "${org_image}" "${new_image}"

    echo "--> Pushing ${new_image}"
    sudo nerdctl -n k8s.io push --insecure-registry "${new_image}"
done

echo "--> Image push process completed."
