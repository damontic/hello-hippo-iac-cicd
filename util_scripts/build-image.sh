#! /bin/bash -ex

function usage {
    cat <<EOF
=============================================================================================
NAME: $0

DESCRIPTION:
    This script builds the hellohippo app docker image and publishes it to AWS ECR.

USAGE:
    $0 AWS_PROFILE VERSION REPOSITORY_NAME COMMIT AWS_USER

PARAMETERS:
    AWS_PROFILE: Refers to an existing AWS PROFILE tied to a specific account.
    
    VERSION: Refer to the newest tag to use for the Docker image that should be aligned with
             the application version.
    
    REPOSITORY_NAME: Refers to the ECR repository NAME in the specified AWS account.

    COMMIT: Refers to git commit sha used to build this version.
=============================================================================================
EOF
}

# Initialize the script

AWS_PROFILE="$1"
VERSION="$2"
REPOSITORY_NAME="$3"
COMMIT="$4"

if [ -z "$AWS_PROFILE" ]; then
    echo -e  "[ERROR]: No AWS_PROFILE was specified.\n"
    usage
    exit 1
fi

if [ -z "$VERSION" ]; then
    echo -e  "[ERROR]: No VERSION was specified.\n"
    usage
    exit 2
fi

if [ -z "$REPOSITORY_NAME" ]; then
    echo -e  "[ERROR]: No REPOSITORY_NAME was specified.\n"
    usage
    exit 3
fi

if [ -z "$COMMIT" ]; then
    echo -e  "[ERROR]: No COMMIT was specified.\n"
    usage
    exit 4
fi

if [ -d /tmp/hellohippo/golang-app ]; then
    rm -rf /tmp/hellohippo/golang-app
fi

git clone --depth 1 --single-branch --no-tags -b main \
    git@github.com:damontic/hello-hippo-iac-cicd.git \
    /tmp/hellohippo/golang-app

cd /tmp/hellohippo/golang-app

REPOSITORY_URI=$(aws --profile "$AWS_PROFILE" \
    --query 'repositories[?contains(repositoryName, `golang`)].repositoryUri' \
    --output text \
    ecr describe-repositories)
    
IMAGE="${REPOSITORY_URI}:$VERSION"

UTC_DATE="$(date -u +%Y-%m-%dT%H:%M:%S%Z)"

docker buildx build \
    --build-arg VERSION="$VERSION" \
    --build-arg COMMIT="$COMMIT" \
    --build-arg DATE="$UTC_DATE" \
    --build-context src="/tmp/hellohippo/golang-app/golang-app" \
    -t  "$IMAGE" \
    /tmp/hellohippo/golang-app/golang-app/docker

aws --profile "$AWS_PROFILE" ecr get-login-password | \
    docker login -u AWS --password-stdin "${REPOSITORY_URI}"

docker push "${IMAGE}"
