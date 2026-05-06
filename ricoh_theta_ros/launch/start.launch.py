from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution, TextSubstitution
from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare


def generate_launch_description():
    device_id_arg = DeclareLaunchArgument(
        'device_id',
        default_value='2',
        description='Video device ID (e.g. 2 for /dev/video2)')

    video_device = PathJoinSubstitution([
        TextSubstitution(text='/dev/video'),
        LaunchConfiguration('device_id'),
    ])

    usb_cam_node = Node(
        package='usb_cam',
        executable='usb_cam_node_exe',
        name='360cam',
        output='screen',
        parameters=[{
            'video_device': video_device,
        }],
        remappings=[
            ('image_raw', '360cam/image_raw'),
            ('camera_info', '360cam/camera_info'),
        ],
    )

    return LaunchDescription([
        device_id_arg,
        usb_cam_node,
    ])
