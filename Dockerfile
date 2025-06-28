FROM ros:noetic

ENV DEBIAN_FRONTEND=noninteractive

# 替换为清华镜像（适配国内）
RUN sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
# 添加 ROS Noetic 源
RUN apt-get install -y curl gnupg2 lsb-release && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - && \
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list 
    
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config 

RUN apt-get install -y --no-install-recommends apt-utils
# 安装 ROS 包和依赖
RUN apt-get install -y \
    ros-noetic-image-geometry ros-noetic-pcl-ros ros-noetic-cv-bridge \
    git cmake build-essential unzip pkg-config autoconf \
    libboost-all-dev libjpeg-dev libpng-dev libtiff-dev \
    libvtk7-dev libgtk-3-dev libatlas-base-dev gfortran \
    libparmetis-dev libtbb-dev \
    python3-wstool python3-catkin-tools

RUN mkdir -p /catkin_ws/src/
RUN git config --global url."https://ghfast.top/https://github.com/".insteadOf "https://github.com/"
RUN git clone https://github.com/borglab/gtsam.git 
RUN cd gtsam && \
      git checkout 4.2 && \
      mkdir build && \
      cd build && \
      cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DGTSAM_BUILD_WITH_MARCH_NATIVE=OFF \
      -DGTSAM_BUILD_TESTS=OFF \
      -DGTSAM_BUILD_EXAMPLES_ALWAYS=OFF \
      -DCMAKE_BUILD_TYPE=Release \
      -DGTSAM_BUILD_UNSTABLE=ON \
      -DGTSAM_POSE3_EXPMAP=ON \
      -DGTSAM_ROT3_EXPMAP=ON \
      -DGTSAM_TANGENT_PREINTEGRATION=OFF \
      -DGTSAM_USE_SYSTEM_EIGEN=ON \
      -DGTSAM_USE_SYSTEM_METIS=ON \
      .. && \
      make -j$(nproc) install

RUN git clone https://github.com/MIT-SPARK/Kimera-VIO-ROS.git /catkin_ws/src/Kimera-VIO-ROS
RUN cd /catkin_ws/src/Kimera-VIO-ROS 
    # && git checkout ___
RUN cd /catkin_ws/src/ && wstool init && \
    wstool merge Kimera-VIO-ROS/install/kimera_vio_ros_https.rosinstall && wstool update

# Build catkin workspace
RUN apt-get install -y ros-noetic-image-pipeline ros-noetic-geometry ros-noetic-rviz

RUN . /opt/ros/noetic/setup.sh && cd /catkin_ws && \
    catkin init && catkin config --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    catkin build
