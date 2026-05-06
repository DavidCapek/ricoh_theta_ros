from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():
    return LaunchDescription([
        Node(
            package='equirec2perspec',
            executable='equirec2perspec_node',
            name='equirec2perspec_node',
            output='screen',
            parameters=[{
                'fov': 90.0,
                'theta': 0.0,
                'phi': 0.0,
                'height': 480,
                'width': 640,
            }],
            remappings=[
                ('input/equirectangular', '360cam/image_raw'),
                ('output/perspective', '360cam/perspective'),
            ],
        ),
    ])
