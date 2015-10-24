#!/usr/bin/env bash
#
# Usage: /path/to/build_conda_env.sh <env type> [project name]
#
# This script creates conda environment.
# It must be launched from the project's root directory.
# It expects to find there an "environments" directory,
# containing Conda environment YAML files.
# If the project name is not given,
# it uses the base name of the project directory.
#
# env type can be "dev" or "prod".

set -eux

MINICONDA_VERSION=${MINICONDA_VERSION-latest}
MINICONDA_ARCH=${MINICONDA_ARCH-x86_64}
MINICONDA_OS=${MINICONDA_OS-Linux}
PROJECT_DIRECTORY=${PROJECT_DIRECTORY-$PWD}
YAML_DIR=${YAML_DIR-$PROJECT_DIRECTORY/environments}

ENV_TYPE=$1
PROJECT_NAME=${2-$(basename $PROJECT_DIRECTORY)}
PYTHON_VERSION=${3-2.7.10}

PYTHON_MAJOR_VERSION=$(echo $PYTHON_VERSION | cut -d. -f1)
if [ $PYTHON_MAJOR_VERSION -eq 2 ]
then
    MINICONDA_NAME=Miniconda
    MINICONDA_INSTALL_PATH=$HOME/.conda2
elif [ $PYTHON_MAJOR_VERSION -eq 3 ]
then
    MINICONDA_NAME=Miniconda3
    MINICONDA_INSTALL_PATH=$HOME/.conda3
fi

ENV_NAME=$PROJECT_NAME-$ENV_TYPE
MINICONDA_INSTALLER_BASENAME=$MINICONDA_NAME-$MINICONDA_VERSION-$MINICONDA_OS-$MINICONDA_ARCH
MINICONDA_INSTALLER_FILENAME=$MINICONDA_INSTALLER_BASENAME.sh
MINICONDA_INSTALLER_PATH=/tmp/$MINICONDA_INSTALLER_BASENAME-$USER.sh
MINICONDA_INSTALLER_URL=https://repo.continuum.io/miniconda/$MINICONDA_INSTALLER_FILENAME
CONDA_PATH=$MINICONDA_INSTALL_PATH/bin/conda

# Download the installer if not done previously
if [ ! -f $MINICONDA_INSTALLER_PATH ]
then
    wget -O$MINICONDA_INSTALLER_PATH $MINICONDA_INSTALLER_URL
    chmod +x $MINICONDA_INSTALLER_PATH
fi

# Install conda if not previously done
if [ ! -d $MINICONDA_INSTALL_PATH ]
then
    $MINICONDA_INSTALLER_PATH -b -p $MINICONDA_INSTALL_PATH
fi
# Create Conda environment if missing
if [ ! -d $MINICONDA_INSTALL_PATH/envs/$ENV_NAME ]
then
    $CONDA_PATH create -y -n $ENV_NAME python=$PYTHON_VERSION
fi
# Ensure the environment matches the environment description
$CONDA_PATH env update -n $ENV_NAME -f $YAML_DIR/$ENV_TYPE.yml
# In dev environment, the project should be installed in development mode
if [ $ENV_TYPE == "dev" ]
then
    $CONDA_PATH run -n $ENV_NAME -- pip install -e $PROJECT_DIRECTORY
fi
