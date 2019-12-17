//
//  ViewController.swift
//  WDRobotControl
//
//  Created by Ruslan Kolosovskyi on 3/5/19.
//  Copyright © 2019 Ruslan Kolosovskyi. All rights reserved.
//

import UIKit
import CoreBluetooth

enum Command: Int {
    case open = 100
    case close = 101

    private var commandsMapping: [Command: String] {
        return [.open: "OPEN.%d;",
                .close: "CLOSE.%d;"]
    }

    var value: String {
        return commandsMapping[self]!
    }
}

class ViewController: UIViewController {
    private let serviceUUID = CBUUID(string: "FFE0")
    private let characteristicUUID = CBUUID(string: "FFE1")
    private let centralQueue = DispatchQueue(label: "com.wdrobotcontrol.centralqueue", attributes: DispatchQueue.Attributes.concurrent)

    private var peripheralDevice: CBPeripheral?
    private var centralManager: CBCentralManager?
    private var characteristic: CBCharacteristic?

    private var command: Command?
    private var previousCommand: String?
    private var speed: Int = 0

    @IBOutlet weak var speedSlider: UISlider!
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet weak var leftJoystickContainerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        centralManager = CBCentralManager(delegate: self, queue: centralQueue)

        for button in buttons {
            // button.layer.borderColor = UIColor.red.cgColor
            // button.layer.borderWidth = 1
            button.contentVerticalAlignment = .fill
            button.contentHorizontalAlignment = .fill
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            button.imageView?.contentMode = .scaleAspectFit
        }

        leftJoystickContainerView.layer.borderWidth = 1
        leftJoystickContainerView.layer.borderColor = UIColor.red.cgColor
        leftJoystickContainerView.layer.cornerRadius = leftJoystickContainerView.frame.height / 2.0
    }

    // MARK: - Instance methods (Actions)

    @IBAction func commandAction(_ sender: UIButton) {
        guard let command = Command(rawValue: sender.tag) else {
            return
        }

        self.command = command

        sendCommand()
    }

    @IBAction func speedSliderAction(_ sender: UISlider) {
        speed = Int(sender.value)
        sendCommand()
    }

    // MARK: - Instance methods (Private)

    private func sendCommand() {
        // TODO: CBCharacteristicWriteType.withResponse
        guard let characteristic = characteristic, let peripheral = peripheralDevice, let command = command else {
            return
        }

        let commandToSend = String(format: command.value, speed)

        guard previousCommand != commandToSend else {
            return
        }

        self.previousCommand = commandToSend

        if let data = commandToSend.data(using: String.Encoding.utf8) {
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        }
    }
}

// MARK: - Protocols ⇣
// MARK: - CBCentralManagerDelegate

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {

        case .unknown:
            print("Bluetooth status is UNKNOWN")

        case .resetting:
            print("Bluetooth status is RESETTING")

        case .unsupported:
            print("Bluetooth status is UNSUPPORTED")

        case .unauthorized:
            print("Bluetooth status is UNAUTHORIZED")

        case .poweredOff:
            print("Bluetooth status is POWERED OFF")

        case .poweredOn:
            print("Bluetooth status is POWERED ON")

            DispatchQueue.main.async { () -> Void in


            }

            centralManager?.scanForPeripherals(withServices: [serviceUUID])
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {

        peripheralDevice = peripheral
        peripheralDevice?.delegate = self

        switch peripheral.state {
        case .disconnected:
            print("Peripheral state: disconnected")
        case .connected:
            print("Peripheral state: connected")
        case .connecting:
            print("Peripheral state: connecting")
        case .disconnecting:
            print("Peripheral state: disconnecting")
        }

        centralManager?.stopScan()
        centralManager?.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async { () -> Void in

        }

        peripheralDevice?.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        if let error = error {
            print(error)
        }

        DispatchQueue.main.async { () -> Void in

        }

        centralManager?.scanForPeripherals(withServices: [serviceUUID])
    }
}

// MARK: - CBPeripheralDelegate

extension ViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {

            if service.uuid == serviceUUID {
                print("Service: \(service)")
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        for characteristic in service.characteristics! {
            print(characteristic)

            if characteristic.uuid == characteristicUUID {
                print("SUCCESS!!!")
                self.characteristic = characteristic

                // peripheral.setNotifyValue(true, for: characteristic)
                // peripheral.readValue(for: characteristic)
                // peripheral.writeValue(<#T##data: Data##Data#>, for: <#T##CBCharacteristic#>, type: <#T##CBCharacteristicWriteType#>)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
    }
}

