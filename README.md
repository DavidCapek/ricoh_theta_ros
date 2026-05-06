# ricoh_theta_ros

The ROS 2 package for RICOH THETA V and Z1 cameras.

## Prerequisites

Having RICOH THETA V/Z1 cameras work on Linux requires a patched libuvc 1.5
driver, a video sampling application, and a dummy v4l2 loopback device, each of
which can be obtained from the following projects respectively.

- [libuvc-theta](https://github.com/ricohapi/libuvc-theta)
- [libuvc-theta-sample](https://github.com/madjxatw/libuvc-theta-sample.git)
- [v4l2loopback](https://github.com/umlaeute/v4l2loopback)

The libuvc-theta-sample repo given above is a fork of the original containing
several pre-created branches specific to different configurations. For example,
the `nvdec` branch uses NVIDIA decoder instead of the open source one; the
`yv12` branch sets the pixel format for the decoded video to YVU420; the
`nvdec-yv12` branch combines the previous two. Check out the branch that
fits your case, or create a new branch with your own modification.

ricoh_theta_ros adds all mentioned 3rd-party dependencies as Git submodules
under the `deps` subdirectory, hence you don't have to download them
manually.

See [RICOH Linux development docs](https://codetricity.github.io/theta-linux/)
if you are interested in more details.

## Installation

Make sure the following ROS 2 packages have been installed:

- `camera_info_manager`
- `ament_cmake`
- `cv_bridge`
- `image_transport`
- `rclcpp`
- `sensor_msgs`
- `usb_cam`

Navigate into your ROS workspace directory and run:

```sh
git -C src clone --recursive https://github.com/DavidCapek/ricoh_theta_ros.git
```

Install any dependencies in the `deps` directory if it is not yet installed.
See the [documentation](#documentation) for how to build, install and configure
them.

Run

```sh
colcon build --packages-select ricoh_theta_ros equirec2perspec
```

to build the workspace.

## Usage

Once the build is done successfully, source the workspace setup script:

```sh
source </path/to/your/ros/workspace>/install/setup.bash
```

### Quick start

The `start.sh` script automates camera wake-up, live streaming setup, and node launch.
Before running it, ensure the following are satisfied:

- The `v4l2loopback` kernel module is loaded (`lsmod | grep v4l2loopback`).
- `gst_loopback` is on your `PATH` (from `libuvc-theta-sample`).
- `ptpcam` is on your `PATH` (from `libptp`).
- Optional: the `ricoh` wrapper script is on your `PATH` (copy from `ricoh_theta_ros/utils/ricoh` to `~/.local/bin` or `/usr/local/bin`).

Run the startup script:

```sh
ros2 run ricoh_theta_ros start.sh
```

The `start.sh` script performs:

- Starting all the stuff required to capture the live streaming data from the
  camera.
- Running a launch file that starts the `usb_cam` node and remaps the `image_raw`
  and `camera_info` topics to the `360cam` namespace.
- Setting up resolution. RICOH THETA V and Z1 support live streaming in either 4K
  (3840x1920) or 2K (1920x960) resolution; `start.sh` sets resolution to 2K to
  reduce latency.

Write your own launch files or startup scripts if the default is not satisfying.

### Manual launch

If you prefer to launch manually instead of using `start.sh`:

```sh
# 1. Ensure v4l2loopback is loaded
sudo modprobe v4l2loopback video_nr=2

# 2. Start the GStreamer loopback (in a separate terminal)
gst_loopback --format 2K

# 3. Launch the camera node (in another terminal)
source </path/to/your/ros/workspace>/install/setup.bash
ros2 launch ricoh_theta_ros start.launch.py device_id:=2
```

### Equirectangular-to-perspective conversion node

To run the perspective conversion node alongside the camera:

```sh
ros2 launch equirec2perspec equirec2perspec.launch.py
```

You can override parameters on the command line, e.g.:

```sh
ros2 launch equirec2perspec equirec2perspec.launch.py fov:=120.0 theta:=45.0 width:=1280 height:=720
```

## Camera control

RICOH has no official camera control application for Linux. Instead of using the
physical buttons, we can use a command line tool bundled with
[libptp](http://libptp.sourceforge.net/) called `ptpcam` together with [RICOH
THETA USB API](https://api.ricoh/docs/theta-usb-api/) to control the cameras on
Linux.

ricoh_theta_ros ships the `ricoh_theta_ros/utils/ricoh` script that facilitates
the camera control by wrapping the execution of `ptpcam` into a set of more
intuitive commands. Copy the `ricoh` script file to a system binary path (e.g.
`~/.local/bin/` or `/usr/local/bin`) and make sure its executable permission bit
is set so that you can run it anywhere.

See the [documentation](#documentation) for how to install libptp.

## Equirectangular-to-Perspective image conversion

RICOH THETA V1 and Z1 stream stitched 360-degree panorama images in live
USB streaming mode, and there is so far no way turning off the internal
stitcher. We use the
[Equirec2Perspec](https://github.com/madjxatw/Equirec2Perspec) library to do
equirectangular-to-perspective conversion.

ricoh_theta_ros has integrated Equirec2Perspec as a ROS catkin package named
**equirec2perspec** (all lowercase), hence you don't have to install it
manually.

To use the equirec2perspec package:

- add `equirec2perspec` as `<build_depend>` and `<exec_depend>` in the
  `package.xml` of your own package.
- In your `CMakeLists.txt`, call `find_package(equirec2perspec REQUIRED)` and
  link against `${equirec2perspec_LIBRARIES}`:

  ```cmake
  find_package(equirec2perspec REQUIRED)
  target_link_libraries(your_target ${equirec2perspec_LIBRARIES})
  ```

then you can reference its header files using the installed include path.

Include the header file as below:

```c++
#include "equirec2perspec/equirec2perspec.h"
```

A standalone ROS 2 node `equirec2perspec_node` is also provided. Launch it with:

```sh
ros2 launch equirec2perspec equirec2perspec.launch.py
```

Parameters (`fov`, `theta`, `phi`, `height`, `width`) can be set via launch or
command line. The node subscribes to `input/equirectangular` and publishes
`output/perspective` (`sensor_msgs/Image`).

See the [documentation](#documentation) for more about it.

## Documentation

The documentation was written in RestructuredText, you need to install Sphinx
and the required theme to build it.

```sh
pip install python3-sphinx sphinx-rtd-theme
cd docs
make html
```

To view docs, open `docs/_build/html/index.html` in your web browser.
