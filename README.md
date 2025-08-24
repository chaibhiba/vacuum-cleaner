Multi-Mode Vacuum Cleaner

This repository contains the source code and documentation of my Final Year Project: a "smart vacuum cleaner robot that can operate in both "automatic" and "manual" modes.  
The project combines "embedded systems, IoT, and mobile development".

---

🚀 Project Overview
The smart vacuum cleaner is designed to navigate autonomously using "ultrasonic sensors" for obstacle avoidance, while also allowing "manual control via a mobile app".  
It is based on an "ESP32 microcontroller", controlled through "Wi-Fi communication", and powered by "DC motors" for both suction and movement.

---

🛠️ Technologies Used
- Arduino / ESP32 (robot control and sensors integration)  
- Flutter (mobile application for manual and automatic modes)  
- Ultrasonic sensors (distance measurement and obstacle detection)  
- DC motors + Motor Drivers (movement and suction system)  
- Wi-Fi communication (ESP32 ↔ Mobile App)  

---

## 📂 Repository Structure

vacuum-cleaner/
│
├── flutter_app/ # Flutter mobile application
│ ├── lib/
│ ├── pubspec.yaml
│ └── ...
│
├── arduino_code/ # Arduino/ESP32 robot code
│ ├── robot.ino
│ └── ...
│
└── README.md # Project documentation

---

📱 Features
- Automatic Mode: autonomous navigation and obstacle avoidance.  
- Manual Mode: control the robot in real-time via the mobile app.  
- Status Monitoring: robot state is displayed in the app.  
- IoT-based Communication: ESP32 connects over Wi-Fi.  

---

⚙️ How to Run
 Arduino Part:
1. Open `arduino_code/robot.ino` in Arduino IDE.  
2. Select ESP32 board and correct COM port.  
3. Upload the code to the ESP32.  

Flutter App:
1. Navigate to `flutter_app/`.  
2. Run:
   ```bash
   flutter pub get
   flutter run

---

👩‍💻 Author

Chaib Hiba 
Master’s student in Embedded Systems & mobility | Passionate about Robotics, Arduino, and Innovative Solutions  

Under the supervision: Djelali Hayet 
MCA at Badji Mokhtar University, Annaba, Department of computer since

- LinkedIn: [linkedin.com/in/chaib-hiba-608922266](https://www.linkedin.com/in/chaib-hiba-608922266)  
- GitHub: [github.com/chaibhiba](https://github.com/chaibhiba)  



