#!/bin/sh

set -e

export PYBIN="$(echo ${1}/bin)"
export PYTHON_SYS_EXECUTABLE="$PYBIN/python"
export PATH="$HOME/.cargo/bin:$PYBIN:$PATH"
export PYTHON_LIB=$(${PYBIN}/python -c "import sysconfig; print(sysconfig.get_config_var('LIBDIR'))")
export LIBRARY_PATH="$LIBRARY_PATH:$PYTHON_LIB"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$PYTHON_LIB"

pip install -U auditwheel

# compile wheels
cd /io
python setup.py sdist bdist_wheel

# move wheels to tempdir
mkdir -p /tmp/wheels
mkdir -p /tmp/repaired
mv /io/dist/*.whl -t /tmp/wheels

# Bundle external shared libraries into the wheels
for whl in /tmp/wheels/*.whl; do
  auditwheel repair "$whl" -w /tmp/repaired
done

# Fix potentially invalid tags in wheel name
for whl in /tmp/repaired/*.whl; do
  auditwheel addtag "$whl" -w /io/dist || cp "$whl" -t /io/dist
done
