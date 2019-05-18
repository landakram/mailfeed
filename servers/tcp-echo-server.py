#!/usr/bin/env python

import socket


TCP_IP = '127.0.0.1'
TCP_PORT = 6504
BUFFER_SIZE = 1024
MESSAGE = "Hello, World!"

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((TCP_IP, TCP_PORT))
s.listen()
conn, addr = s.accept()
with conn:
    while True:
        data = conn.recv(BUFFER_SIZE)
        if not data:
            break
        print(data)
        conn.sendall(data)
