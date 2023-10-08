# Networks Part B

## Implementing TCP Functionality using UDP

Implementing a client server system that is used to achieve a TCP-like functionality over UDP. The primary functionalities implemented are data sequencing (splitting data into smaller chunks) and retransmissions.

1. Data Sequencing: The sender will divide the text to be sent into smaller chunks (here taken 5 bytes), each chunk has a unique identifier (index number), and shares the total chunk count along with the chunk, everytime it sends a chunk. The receiver assembles them based on their sequence numbers to reconstruct the complete text.
2. Retransmission: Upon recieving a data chunk, the receiver send acknowledgement back to the sender with the corresponding sequence number. If no ACK is received within 0.1 seconds, the sender will resend the chunk. (This process happens without waiting for acknowledgments of previous chunks, i.e sending chunk 2 doesn't wait for recieving acknowledgement for chunk 1)

## Working

Each chunk is a struct which contains the information to be sent (the 5 bytes), the index number of the chunk being sent, and the total number of chunks that will be sent. Each message sent is also denoted by a unique message number, sent along with each chunk. 

### Sending Data

- Creates UDP Socket.
- Computing the number of chunks the data needs to be split into using the given chunk size (5 bytes).
- Splits data into the chunks and constructs packets (structs).
- Now we begin iterating over all chunks, and sending the chunk, before sending the chunk, obtain the time using gettimeofday() function and store it in a Time array (for each chunk), Now everytime we will iterate over the array to check if a chunk which hasn't recieved acknoledgment yet, has exceed it's 0.1 second time.
- Also everytime check for acknowledgment being recieved using a non-blocking recvfrom() function, we can make the recvfrom function non-blocking by setting flags using fcntl for the socket.
- Anytime we recieve an acknowledgment marks that index (recieved via acknowledgement) as recieved.
- Continue checking for chunks that haven't been acknowledged to exceed 0.1 seconds till last data send, and send them again, till all the chunks are acknowledged, this can be checked by comparing with the number of chunks sent along with the chunk.

### Recieving data

- Creates a UDP Socket.
- Waits to recieve a packet.
- If packet is recieved obtain the required information, about the data that will be sent, like number of chunks that will be sent and message number.
- Create a recieved array of [number of chunks] size and everytime, everytime we recieved a chunk with an index number, mark that index number as recieved and store that chunk in chunk array of [number of chunks] size at the same index. Also send acknowledgement for the chunk, by sending the index number of the chunk back to the sender.
- Continue recieving till all chunks are recieved, again can be checked by number of chunks which is passed along with each chunk
- Once all chunks for a particular msg number are recieved, we can simply print the required data, by iterating over the entire chunks array and taking the data to reconstruct the original string.

###

The client and server can do the above while sending and recieving data to achieve communication.

## Difference with Actual TCP

1. I have tried to simulate TCP using UDP, including acknowledgments to guarantee the transmission of data. TCP is a much more complex protocol with much better measures to ensure delivery, and with less overhead.
2. The implemented code does not implement flow control or congestion control mechanisms, which are crucial aspects of TCP that optimize data transmission and ensure network stability.
3. In the implemented code, sequence numbers are assigned manually to each chunk for data sequencing. In TCP, sequence numbers are dynamically assigned and managed by the protocol to ensure ordered and reliable delivery of data, additionally in TCP each chunk can have a dynamic size, rather than the fixed size used in our implementation, and the actual TCP adds some headers like (source port number, destination port address, sequence number (included in my implementation), acknowledgement number, header length, control flags, window size, checksum, urgent pointer etc.).
4. In actual TCP the starting address/offset of the data to be next sent is sent as acknowledgement number, rather than the index number sent back as acknowledgement in my implementation.
5. A SYN bit (sequence number for first chunk) is sent to check for connection in actual TCP, instead we send the number of packets to be sent and make use of it to check connection.
6. We do not have a window (which will only send ACK till a maximum limit), we keep on sending the package whether or not ACK is received for it or not and then resend according to ACK check. In actual TCP, there's a window.
7. We assume that at a time only one of the two is sending the message, the communication can be done both ways, but at one instant only one is sending the message to the other, while it differs in actual TCP

## Incorporating Flow Control

### What if Flow Control?
Flow control in TCP allows regulating data transmission to match the receiver's processing capacity, preventing overload and ensuring efficient communication.

We can use sliding windows and acknowledgments to manage data flow dynamically. The sliding window will allow the sender to control the amount of unacknowledged data being sent at a time, preventing overwhelming the receiver or the network. We'll also update the receiver to handle this sliding window. The sender will only transmit data within the sender's window, and the receiver will only accept data within the receiver's window.

To extend the implementation :

1. On the sender's side, we can modify the packet structure to include the window size. Then maintaining a count of the window size, to know the start and end of the window. The sender will then trasmit those chunks to the reciever.
2. This can then be communicated to the receiver, who can keep track of the data transmission and adjust its window size accordingly. When the reciever recieves, the data (it might be out of order as well), it will find the last chunk sent in order (within the window size of the reciever) and modify it's sliding window accordingly and send back acknowledgment till that chunk.
3. Upon recieving this the sender can modify it's sliding window to now send data from the chunk after the last chunk that recieved acknowledgment.
4. We can repeat this process untill all chunks are sent.

This facilitates proper flow control and ensures that the sender does not overwhelm the receiver with too much unacknowledged data at the same time.

## Assumptions made
- Not considering the situation of a deadlock.

## References

- [TCP](https://www.educative.io/answers/what-is-tcp)
- [TCP on Wikipedia](https://en.wikipedia.org/wiki/Transmission_Control_Protocol)
- [Flow Control](https://en.wikipedia.org/wiki/Transmission_Control_Protocol#Flow_control)
