#!/bin/bash

version=${1:-$versions}

echo "Downloading, compiling, and listing objects for version $version"

function download {
  TARFILE="$1.tar.gz"
  echo "==============="
  echo "Downloading $TARFILE:"
  wget --quiet "https://cran.r-project.org/src/base/R-2/$TARFILE"
  if [[ $? > 0 ]]
  then
    echo "wget failed. Stopping."
    exit
  fi
  tar -zxf $TARFILE
  if [[ $? > 0 ]]
  then
    echo "untar failed. Stopping."
    exit
  fi
}

function compile {
  echo "==============="
  echo "Compiling $1:"
  cd $1
  # these speed up configuration but don't remove any functions from ls()
  # tcltk must be enabled though; and x, to avoid obscure 2.8.0 bug
  CFLAGS="-O0 -pipe" FFLAGS=-O0 ./configure --with-recommended-packages=no \
      --with-libpng=no --with-libjpeg=no \
      --with-tcl-config=/usr/lib/tcl8.4/tclConfig.sh \
      --with-tk-config=/usr/lib/tk8.4/tkConfig.sh --with-tcl-tk=yes
  make -j4
  if [[ $? > 0 ]]
  then
    echo "make failed. Stopping."
    exit
  fi
  cd ..
}

function run_list_objects {
  echo "==============="
  echo "Running list-objects.R for $1:"
  PATH=/usr/X11R6/bin:$PATH xvfb-run $1/bin/R CMD BATCH --slave --no-timings list-objects.R docker-data/stdout-$1 
  
  if [[ $? > 0 ]]
  then
    echo "R CMD BATCH failed. Stopping."
    exit
  fi
}

if [ "$version" == "all" ]; then
  while read VERSION; do
    if [[ $VERSION == x* ]]; then continue; fi
    download $VERSION
  done <R-2.x-source-versions.txt

  wget --quiet "https://cran.r-project.org/src/base/R-3/R-3.0.0.tar.gz"
  tar -zxf R-3.0.0.tar.gz

  while read VERSION; do
    if [[ $VERSION == x* ]]; then continue; fi
    compile $VERSION
    run_list_objects $VERSION
  done <R-2.x-source-versions.txt

  compile R-3.0.0
  run_list_objects R-3.0.0
else
  download $version
  compile $version
  run_list_objects $version
fi