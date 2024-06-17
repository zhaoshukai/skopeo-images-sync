#!/bin/bash
# Synchronize images by skopeo copy
# Use YQ to Parse ymal file

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin; export PATH

IMAGES_FILE=$1
IMAGES_REPO=$2
SKOPEO_USERNAME=${USERNAME}
SKOPEO_PASSWORD=${PASSWORD}
SKOPEO_AUTHFILE=${AUTHFILE:-'./containers/auth.json'}

getSyncStatus()
## 获取同步状态，参数：注册表名称, 仓库名称， Tag名称
{
    local REGISTRY=$1
    local REPOSITORY=$2
    local TAG=$3
    local SYNCSTATUS_FILE=${4:-$IMAGES_FILE}.sync

    if [ ! -f "${SYNCSTATUS_FILE}" ]; then
        echo -e "# 已同步镜像列表\n" >${SYNCSTATUS_FILE}
    fi
    eval $(echo "yq -e '.\"${REGISTRY}\".images.\"${REPOSITORY}\".[] | select (. == \"${TAG}\")' ${SYNCSTATUS_FILE}") 2>/dev/null
    return $?
}

updateSyncStatus()
## 写入同步结果，参数：注册表名称, 仓库名称， Tag名称
{
    local REGISTRY=$1
    local REPOSITORY=$2
    local TAG=$3
    local SYNCSTATUS_FILE=${4:-$IMAGES_FILE}.sync

    local line=$(eval $(echo "yq '.\"${REGISTRY}\".images.\"${REPOSITORY}\".[]' ${SYNCSTATUS_FILE} | wc -l"))
    eval $(echo "yq -i '.\"${REGISTRY}\".images.\"${REPOSITORY}\".["${line}"] = \"${TAG}\"' ${SYNCSTATUS_FILE}")
    eval $(echo "yq -i '.\"${REGISTRY}\".updated = now' ${SYNCSTATUS_FILE}")
}

getRegistry()
## 获取注册表地址列表
{
    local IMAGES_FILE=${1:-$IMAGES_FILE}

    local registry=$(yq 'keys' ${IMAGES_FILE} | awk '{print $2}')
    echo $registry
}

getRepository()
## 获取仓库地址列表，参数：注册表名称
{
    local REGISTRY=$1
    local IMAGES_FILE=${2:-$IMAGES_FILE}

    local repository=$(eval $(echo "yq '.\"${REGISTRY}\".images[] | key' ${IMAGES_FILE}"))
    echo $repository
}

getTag()
## 获取仓库Tags列表，参数：注册表名称, 仓库名称
{
    local REGISTRY=$1
    local REPOSITORY=$2
    local IMAGES_FILE=${3:-$IMAGES_FILE}

    local tags=$(eval $(echo "yq '.\"${REGISTRY}\".images.\"${REPOSITORY}\"' ${IMAGES_FILE} ") | awk '{print $2}')
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
            if [ ! $(getSyncStatus ${reg} ${repo} ${tag}) ]; then
                echo "+ skopeo copy docker://${reg}/${repo}:${tag} docker://${IMAGES_REPO}/${repo}:${tag}"
                skopeo copy --retry-times 5 docker://${reg}/${repo}:${tag} docker://${IMAGES_REPO}/${repo}:${tag}
                updateSyncStatus ${reg} ${repo} ${tag}
            fi
        done
    done
done
