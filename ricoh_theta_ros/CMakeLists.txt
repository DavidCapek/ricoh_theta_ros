cmake_minimum_required(VERSION 3.10)
project(ricoh_theta_ros)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ament_cmake REQUIRED)

install(
  DIRECTORY launch
  DESTINATION share/${PROJECT_NAME}
)

install(
  PROGRAMS scripts/start.sh utils/ricoh
  DESTINATION lib/${PROJECT_NAME}
)

ament_package()
