#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/image.hpp>
#include <cv_bridge/cv_bridge.hpp>
#include <image_transport/image_transport.hpp>
#include "equirec2perspec/equirec2perspec.h"

class Equirec2PerspecNode : public rclcpp::Node
{
public:
  Equirec2PerspecNode() : Node("equirec2perspec_node")
  {
    this->declare_parameter("fov", 90.0f);
    this->declare_parameter("theta", 0.0f);
    this->declare_parameter("phi", 0.0f);
    this->declare_parameter("height", 480);
    this->declare_parameter("width", 640);

    fov_ = this->get_parameter("fov").as_double();
    theta_ = this->get_parameter("theta").as_double();
    phi_ = this->get_parameter("phi").as_double();
    height_ = this->get_parameter("height").as_int();
    width_ = this->get_parameter("width").as_int();

    RCLCPP_INFO(this->get_logger(), "Equirec2PerspecNode started with FOV=%.1f theta=%.1f phi=%.1f output=%dx%d",
                fov_, theta_, phi_, width_, height_);

    pub_ = image_transport::create_publisher(this, "output/perspective");
    sub_ = image_transport::create_subscription(
      this, "input/equirectangular",
      std::bind(&Equirec2PerspecNode::imageCallback, this, std::placeholders::_1),
      "raw");
  }

private:
  void imageCallback(const sensor_msgs::msg::Image::ConstSharedPtr & msg)
  {
    try {
      cv_bridge::CvImageConstPtr cv_ptr = cv_bridge::toCvShare(msg, sensor_msgs::image_encodings::BGR8);
      cv::Mat perspective;
      converter_.convert(cv_ptr->image, perspective, static_cast<float>(fov_),
                         static_cast<float>(theta_), static_cast<float>(phi_), height_, width_);

      sensor_msgs::msg::Image::SharedPtr out_msg = cv_bridge::CvImage(
        msg->header, "bgr8", perspective).toImageMsg();
      pub_.publish(out_msg);
    } catch (const cv_bridge::Exception & e) {
      RCLCPP_ERROR(this->get_logger(), "cv_bridge exception: %s", e.what());
    }
  }

  Equirec2Perspec converter_;
  image_transport::Publisher pub_;
  image_transport::Subscriber sub_;
  double fov_;
  double theta_;
  double phi_;
  int height_;
  int width_;
};

int main(int argc, char ** argv)
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<Equirec2PerspecNode>());
  rclcpp::shutdown();
  return 0;
}
