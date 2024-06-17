#!/bin/bash
# Synchronize images by skopeo copy
# Use YQ to Parse ymal file

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin; export PATH

IMAGES_FILE=$1
IMAGES_REPO=$2
SKOPEO_USERNAME=${USERNAME}
SKOPEO_PASSWORD=${PASSWORD}
SKOPEO_AUTHFILE=${AUTHFILE:-'./containers/auth.json'}

getRegistry()
## 获取注册表地址列表
{
    local IMAGES_FILE=${1:-$IMAGES_FILE}
    local registry=$(yq -e 'keys' ${IMAGES_FILE} | awk '{print $2}')
    echo $registry
}

getRepository()
## 获取仓库地址列表，参数：注册表名称
{
    local REGISTRY=$1
    local IMAGES_FILE=${2:-$IMAGES_FILE}
    local repository=$(eval $(echo "yq -e '.\"${REGISTRY}\".images[] | key' ${IMAGES_FILE}"))
    echo $repository
}

getTag()
## 获取仓库Tags列表，参数：注册表名称, 仓库名称
{
    local REGISTRY=$1
    local REPOSITORY=$2
    local IMAGES_FILE=${3:-$IMAGES_FILE}
    local tags=$(eval $(echo "yq -e '.\"${REGISTRY}\".images.\"${REPOSITORY}\"' ${IMAGES_FILE} ") | awk '{print $2}')
    echo $tags
}


## Login to the Container registry
# if [ ! -f "${SKOPEO_AUTHFILE}" ]; then
#     echo "${SKOPEO_PASSWORD}" | skopeo login -u "${SKOPEO_USERNAME}" --password-stdin ${IMAGES_REPO%%/*}
# fi

## Synchronize Container images
# skopeo copy docker://docker.io/grafana/grafana:9.5.3 docker://hub.local.lan/grafana/grafana:9.5.3
# REGISTRY=$(getRegistry)
for reg in $(getRegistry); 
do
    # REPOSITORY=$(getRepository $reg)
    for repo in $(getRepository $reg); 
    do
        # TAGS=$(getTag $reg $repo)
        for tag in $(getTag $reg $repo); 
        do
            echo "+ skopeo copy docker://${reg}/${repo}:${tag} docker://${IMAGES_REPO}/${repo}:${tag}"
            skopeo copy --retry-times 5 docker://${reg}/${repo}:${tag} docker://${IMAGES_REPO}/${repo}:${tag}
        done
    done
done
