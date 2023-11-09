# CarPlay-AWS-App Practice
Based on [AWS Full Stack Swift with Apple CarPlay](https://github.com/aws-samples/aws-serverless-fullstack-swift-apple-carplay-example) 

## Added features

### Air Quality Notification: 

The Air Quality Notification feature is designed to keep users informed about the current air quality index (AQI) levels. Notifications are pushed to the user based on real-time AQI data, ensuring that drivers are promptly alerted about the air quality in their vicinity, which is especially crucial for sensitive groups or during events of high pollution.

<p float="left">
  <img src="https://github.com/tsunami776/CarPlay-AWS-App-practice/assets/43768723/a92564fd-43dd-4ef2-896d-be111c101649" width="400" />
  <img src="https://github.com/tsunami776/CarPlay-AWS-App-practice/assets/43768723/19b2e989-2c9c-4170-91d5-0ead97439e6b" width="400" /> 
</p>

### Geofence Notification: 

With Geofence Notification, the system creates a virtual perimeter for real-world geographic areas. When the user's vehicle enters one of these defined geofence zones, a message will be saved in DynamoDB via AppSync and pushed to the user's CarPlay screen. This service allows for customized alerts and location-based messaging, enhancing the driving experience with timely and relevant information.

![Geofence Notification](https://github.com/tsunami776/CarPlay-AWS-App-practice/assets/43768723/102038ba-5855-4fe8-91c3-4bec248025d2)
