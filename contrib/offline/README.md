# Offline deployment

## manage-offline-container-images.sh

Container image collecting script for offline deployment

This script has two features:
(1) Get container images from an environment which is deployed online, or set IMAGES_FROM_FILE
    environment variable to get images from a file (e.g. temp/images.list after running the
    ./generate_list.sh script).
(2) Deploy local container registry and register the container images to the registry.

Step(1) should be done online site as a preparation, then we bring the gotten images
to the target offline environment. if images are from a private registry,
you need to set `PRIVATE_REGISTRY` environment variable.
Then we will run step(2) for registering the images to local registry, or to an existing
registry set by the `DESTINATION_REGISTRY` environment variable. By default, the local registry
will run on port 5000. This can be changed with the `REGISTRY_PORT` environment variable

Step(1) can be operated with:

```shell
manage-offline-container-images.sh   create
```

Step(2) can be operated with:

```shell
manage-offline-container-images.sh   register
```

## generate_list.sh

This script generates the list of downloaded files and the list of container images by `roles/kubespray_defaults/defaults/main/download.yml` file.

Run this script will execute `generate_list.yml` playbook in kubespray root directory and generate four files,
all downloaded files url in files.list, all container images in images.list, jinja2 templates in *.template.

```shell
./generate_list.sh
tree temp
temp
├── files.list
├── files.list.template
├── images.list
└── images.list.template
0 directories, 5 files
```

In some cases you may want to update some component version, you can declare version variables in ansible inventory file or group_vars,
then run `./generate_list.sh -i [inventory_file]` to update file.list and images.list.

## manage-offline-files.sh

This script will download all files according to `temp/files.list` and run nginx container to provide offline file download.

Step(1) generate `files.list`

```shell
./generate_list.sh
```

Step(2) download files and run nginx container

```shell
./manage-offline-files.sh
```

when nginx container is running, it can be accessed through <http://127.0.0.1:8080/>.

## upload2artifactory.py

After the steps above, this script can recursively upload each file under a directory to a generic repository in Artifactory.

Environment Variables:

- USERNAME -- At least permissions'Deploy/Cache' and 'Delete/Overwrite'.
- TOKEN -- Generate this with 'Set Me Up' in your user.
- BASE_URL -- The URL including the repository name.

Step(3) (optional) upload files to Artifactory

```shell
cd kubespray/contrib/offline/offline-files
export USERNAME=admin
export TOKEN=...
export BASE_URL=https://artifactory.example.com/artifactory/a-generic-repo/
./upload2artifactory.py
```
## 중요
인터넷접근이 되는 노드 또는 VM를 일반적으로 Bastion VM 또는 노드라고 합니다.
이런 노드 또는 VM에서  이 작업을 해야 됩니다.

(1) 처음 설치하는 노드라면 없기 때문에 구성합니다.
apt install containerd

# 링크 복사 후 다운로드
wget https://github.com/containerd/nerdctl/releases/download/v2.1.2/nerdctl-2.1.2-linux-amd64.tar.gz

# /usr/local에 압축 해제
tar Cxzvvf /usr/local/bin nerdctl-2.1.2-linux-amd64.tar.gz

# 링크 복사 후 다운로드
wget https://github.com/containerd/nerdctl/releases/download/v2.1.2/nerdctl-2.1.2-linux-amd64.tar.gz

# /usr/local에 압축 해제
tar Cxzvvf /usr/local/bin nerdctl-2.1.2-linux-amd64.tar.gz

(2)
1단계: 이미지 목록 생성하기
generate_list.sh를 사용하여 Ansible 인벤토리로부터 kubectl 없이 이미지 목록 파일을 생성합니다.
bash ./contrib/offline/generate_list.sh -i inventory/mycluster/hosts.yml

이 명령을 실행하면 contrib/offline/temp/images.list 파일이 생성됩니다

(3)
2단계: 생성된 목록 파일로 이미지 다운로드하기
IMAGES_FROM_FILE 환경 변수를 방금 생성한 파일 경로로 지정하고 manage-offline-container-images.sh를 실행합니다

# contrib/offline 디렉터리에서 실행
# 환경 변수 설정
export IMAGES_FROM_FILE="${PWD}/temp/images.list"

# 스크립트 실행
bash ./manage-offline-container-images.sh create

이제 스크립트는 kubectl을 실행하지 않고 temp/images.list 파일의 내용을 읽어 필요한 모든 쿠버네티스 이미지를 다운로드하고, 
완전한 container-images.tar.gz 파일을 생성할 것입니다.
