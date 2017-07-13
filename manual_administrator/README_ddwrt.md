# Setup ddwrt on Linksys WRT 3200

### 1. Prepare Router <a id="Prepare"/>
- Connect Ethernetcable with PC and Router
- Connect Powercable with Router

![WRT3200](doc/linksys_wrt3200_custom.jpg)

### 2. Flash DDWRT <a id="Flash"/>
- Download ddwrt image for wrt3200: <br>
  http://download1.dd-wrt.com/dd-wrtv2/downloads/betas/2017/07-08-2017-r32597/linksys-wrt3200acm/factory-to-ddwrt.bin
- Open Browser and enter Address `192.168.1.1`. You should now see a LinkSys Smart Wifi Setup Screen.
- Accept Lizenz and click on `manual Configuration`.

![Flash1](doc/Flash1.PNG)
  
- Now click on `Anmelden` and ether the default Passwort: admin

![Flash2](doc/Flash2.PNG)

- You should now see the Linksys web admin page:
- Go to `Konnektivität`, click on `Datei auswählen` on the manual firmware update setting and select the in step 1 downloaded `factory-to-ddwrt.bin`

![Flash3](doc/Flash3.PNG)
![Flash5](doc/Flash5.PNG)

- Press `start` to start the flash progress <br>
  Accept the upcomming warings and restart the Router once the process is finished
 
### 3. Setup DDWRT <a id="DDWRT"/>
- After the Router restartet got to the Adress `192.168.1.1` by entering it in the Address Bar of you web browser
- Now enter a new username and password <br>
  user: admin
  password: root
- You should now see the ddwrt admin web page

![ddwrt1](doc/ddwrt1.PNG)

- Download the ddwrt template config: <br>
  https://github.com/ipa320/setup_cob4/blob/master/ddwrt_backup/linksys_wrt3200_initial_config.bin?raw=true
- Go to Administration -> Backup <br>
  Select the downloaded file under Restore Settings and click `Restore`.
  
![ddwrt2](doc/ddwrt2.PNG)

- Now reboot the Router.

### 4. Customize DDWRT Settings <a id="Custom"/>
- The DDWRT WEB Admin page is now under `10.4.1.1` accessible. Open `10.4.1.1` with your web browser.
- Got to `Setup -> Basic-Setup` and change the following settings according to your robot.<br>
  - Router Name
  - Hostname
  - Domain Name
  - Router IP (Remember that you have to reopen the web admin page with new new IP Address)
- Go to `Wireless -> Basic Settings` and change the following settings acccording to your robot. <br>
  - Wireless Network Name SSID
  - 