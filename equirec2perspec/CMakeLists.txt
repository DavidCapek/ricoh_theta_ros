cmake_minimum_required(VERSION 3.10)
project(equirec2perspec CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(image_transport REQUIRED)
find_package(OpenCV REQUIRED)

# OpenCV 4 defines some macros in different headers
if(OpenCV_VERSION_MAJOR EQUAL 4)
  add_compile_definitions(OPENCV_VER_4)
endif()

include_directories(include "${OpenCV_INCLUDE_DIRS}")

# Library
add_library(${PROJECT_NAME} SHARED src/equirec2perspec.cpp)
target_link_libraries(${PROJECT_NAME} "${OpenCV_LIBRARIES}")
target_compile_options(${PROJECT_NAME} PRIVATE -O3)
set_target_properties(${PROJECT_NAME} PROPERTIES
  LIBRARY_OUTPUT_NAME equi2pers
)

# Node
add_executable(${PROJECT_NAME}_node src/equirec2perspec_node.cpp)
target_link_libraries(${PROJECT_NAME}_node ${PROJECT_NAME})
ament_target_dependencies(${PROJECT_NAME}_node rclcpp sensor_msgs cv_bridge image_transport OpenCV)

install(
  TARGETS ${PROJECT_NAME} ${PROJECT_NAME}_node
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION lib/${PROJECT_NAME}
)

install(
  DIRECTORY include/
  DESTINATION include
)

install(
  DIRECTORY launch
  DESTINATION share/${PROJECT_NAME}
)

ament_export_include_directories(include)
ament_export_libraries(${PROJECT_NAME})
ament_export_dependencies(OpenCV)

ament_package()
