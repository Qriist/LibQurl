import socket

HOST = '127.0.0.1'
PORT = 12345

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
    server_socket.bind((HOST, PORT))
    server_socket.listen()
    print(f"Server listening on {HOST}:{PORT}")

    while True:
        conn, addr = server_socket.accept()
        with conn:
            print(f"Connected by {addr}")

            while True:
                try:
                    data = conn.recv(1024)

                    if not data:
                        print("Client disconnected.")
                        break

                    print(f"Received: {data.decode('utf-8')}")
                    reply = "Got your message!"
                    conn.sendall(reply.encode('utf-8'))

                except (ConnectionResetError, BrokenPipeError):
                    print("Connection lost.")
                    break