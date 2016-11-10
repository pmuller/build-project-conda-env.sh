#!/usr/bin/env bash

set -eux

TMPDIR=${TMPDIR-/tmp}
MINICONDA_VERSION=${MINICONDA_VERSION-latest}
MINICONDA_ARCH=${MINICONDA_ARCH-x86_64}
MINICONDA_OS=${MINICONDA_OS-Linux}
PROJECT_DIRECTORY=${PROJECT_DIRECTORY-$PWD}
CONDA_REQUIREMENTS_DIR=${CONDA_REQUIREMENTS_DIR-$PROJECT_DIRECTORY/requirements/conda}
PIP_REQUIREMENTS_DIR=${PIP_REQUIREMENTS_DIR-$PROJECT_DIRECTORY/requirements/pip}
PIP_INSTALL_OPTIONS=${PIP_INSTALL_OPTIONS-"--no-binary :all:"}

ENV_TYPE=${1-dev}
PROJECT_NAME=${2-$(basename $PROJECT_DIRECTORY)}
PYTHON_VERSION=${3-2.7.10}

# Choose a Conda installer based on the requested Python version
PYTHON_MAJOR_VERSION=$(echo $PYTHON_VERSION | cut -d. -f1)
if [ $PYTHON_MAJOR_VERSION -eq 2 ]
then
    MINICONDA_NAME=Miniconda
elif [ $PYTHON_MAJOR_VERSION -eq 3 ]
then
    MINICONDA_NAME=Miniconda3
else
    echo "Invalid python version: $PYTHON_VERSION" >&2
    exit -1
fi

ENV_NAME=$PROJECT_NAME-$ENV_TYPE
MINICONDA_INSTALL_PATH=${MINICONDA_INSTALL_PATH-${HOME-$TMPDIR}/.conda}
MINICONDA_BASENAME=$MINICONDA_NAME-$MINICONDA_VERSION-$MINICONDA_OS-$MINICONDA_ARCH
MINICONDA_INSTALLER_PATH=$TMPDIR/$MINICONDA_BASENAME-$(id -u).sh
MINICONDA_INSTALLER_URL=https://repo.continuum.io/miniconda/$MINICONDA_BASENAME.sh
CONDA_PATH=$MINICONDA_INSTALL_PATH/bin/conda

# Download the installer if not done previously
if [ ! -f $MINICONDA_INSTALLER_PATH ]
then
    curl -o $MINICONDA_INSTALLER_PATH $MINICONDA_INSTALLER_URL
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

# Ensure the environment honors Conda requirements
if [ -f $CONDA_REQUIREMENTS_DIR/$ENV_TYPE.yml ]
then
    $CONDA_PATH env update -n $ENV_NAME -f $CONDA_REQUIREMENTS_DIR/$ENV_TYPE.yml
fi

# Ensure the environment honors pip requirements
if [ -f $PIP_REQUIREMENTS_DIR/$ENV_TYPE.txt ]
then
    $CONDA_PATH run -n $ENV_NAME -- \
        pip install $PIP_INSTALL_OPTIONS \
                    -r $PIP_REQUIREMENTS_DIR/$ENV_TYPE.txt
fi
