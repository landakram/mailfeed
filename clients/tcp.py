#!/usr/bin/env python

import socket


TCP_IP = '127.0.0.1'
TCP_PORT = 6504
BUFFER_SIZE = 1024
MESSAGE = "Hello, World!\n"

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((TCP_IP, TCP_PORT))
s.sendall(MESSAGE.encode())
data = s.recv(len(MESSAGE))
s.close()

print("received data:", data)
