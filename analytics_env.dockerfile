FROM ubuntu:22.04
LABEL version="1.0" description="R, Python and packages container" other="yama"

RUN apt-get update && apt-get install -y sudo
# ARG USERNAME=name_user
# ARG GROUPNAME=user
# ARG PASSWORD=yamayama
ARG UID=1000 \
    && GID=1000 \
    && GROUPNAME \
    && USERNAME \
    && PASSWORD \
    && PYTHON_VERSION

# RUN echo "GID is ${GID}" && echo "GROUPNAME is ${GROUPNAME}"
RUN groupadd --gid $GID $GROUPNAME && \
    useradd -m -s /bin/bash -u $UID -g $GID -G sudo $USERNAME && \
    echo $USERNAME:$PASSWORD | chpasswd && \
    echo "$USERNAME   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER $USERNAME
WORKDIR /home/$USERNAME/

# R
## RとRstudioのインストール
# RUN pip install /tmp/requirements.txt
COPY r_packages_list.txt /tmp/
RUN sudo apt-get install r-base -y --no-install-recommends && \
    sudo apt-get install -y locales build-essential gdebi-core \
        wget libcurl4-openssl-dev libfontconfig1-dev libxml2-dev \
        libharfbuzz-dev libfribidi-dev gfortran libatlas-base-dev \
        libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev && \
    sudo locale-gen en_US.UTF-8 && \
    wget https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2023.12.1-402-amd64.deb && \
    sudo gdebi -n rstudio-server-2023.12.1-402-amd64.deb && \
    sudo R -e "install.packages(scan('/tmp/r_packages_list.txt', what = character(), sep = '\n', blank.lines.skip = TRUE),dependencies = TRUE)" && \
    sudo R -e "devtools::install_github('ManuelHentschel/vscDebugger')"

# Python
# pythonのインストール
COPY python_packages.text /tmp/
RUN sudo apt-get install curl git -y && \
    curl https://pyenv.run | bash && \
    export PYENV_ROOT="$HOME/.pyenv" && \
    echo [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH" && \
    eval "$(pyenv init -)" && \
    eval "$(pyenv virtualenv-init -)" && \
    sudo apt-get install -y tk-dev libsqlite3-dev libffi-dev && \
    pyenv install $PYTHON_VERSION && \
    sudo apt install python3.10-venv -y && \
    python3 -m venv .home_pyenv && \
    . .home_pyenv/bin/activate && \
    pip install --upgrade pip && \
    pip install -r /tmp/python_packages.text

# ENTRYPOINT sudo rstudio-server start
# # ENTRYPOINT ["sudo", "rstudio-server", "start"]
# CMD ["/init"]
