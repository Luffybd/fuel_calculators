package com.library.network;

import java.io.*;
import java.net.*;
import java.util.*;
import java.util.concurrent.*;

// ==========================================
// 1. CONCURRENT RESOURCE DOMAIN MODELS
// ==========================================
class NetworkBook implements Serializable {
    private static final long serialVersionUID = 2L;
    private final String id;
    private final String title;
    private boolean isBorrowed;

    public NetworkBook(String id, String title) {
        this.id = id;
        this.title = title;
        this.isBorrowed = false;
    }

    public String getId() { return id; }
    public String getTitle() { return title; }
    public synchronized boolean isBorrowed() { return isBorrowed; }
    
    public synchronized boolean borrowItem() {
        if (isBorrowed) return false;
        isBorrowed = true;
        return true;
    }

    public synchronized void returnItem() {
        isBorrowed = false;
    }

    @Override
    public String toString() {
        return String.format("[%s] '%s' - Checked Out: %b", id, title, isBorrowed);
    }
}

// ==========================================
// 2. CONCURRENT MULTITHREADED SERVER ENGINE
// ==========================================
class CentralLibraryServer {
    private static final int PORT = 8085;
    // Thread-safe map to handle thousands of concurrent read/write queries safely
    private final Map<String, NetworkBook> inventory = new ConcurrentHashMap<>();
    private final ExecutorService threadPool = Executors.newCachedThreadPool();

    public void start() {
        // Seed initial shared concurrent records
        inventory.put("101", new NetworkBook("101", "Design Patterns (GoF)"));
        inventory.put("102", new NetworkBook("102", "Introduction to Algorithms"));
        inventory.put("103", new NetworkBook("103", "Concurrency in Practice"));

        System.out.println("[SERVER] Central Database Storage Pool Engine deployed.");
        try (ServerSocket serverSocket = new ServerSocket(PORT)) {
            System.out.println("[SERVER] Listening for remote network clients on Port: " + PORT);

            while (!Thread.currentThread().isInterrupted()) {
                Socket clientSocket = serverSocket.accept();
                System.out.println("[SERVER] Secure socket established with client: " + clientSocket.getRemoteSocketAddress());
                
                // Offload network socket processing instantly to the thread pool execution engine
                threadPool.execute(new ClientHandler(clientSocket, inventory));
            }
        } catch (IOException e) {
            System.err.println("[SERVER CRITICAL ERROR] Networking pipeline crashed: " + e.getMessage());
        } finally {
            threadPool.shutdown();
        }
    }

    // ==========================================
    // 3. NETWORK CLIENT CONNECTION HANDLER (Runnable Task)
    // ==========================================
    private static class ClientHandler implements Runnable {
        private final Socket socket;
        private final Map<String, NetworkBook> inventory;

        public ClientHandler(Socket socket, Map<String, NetworkBook> inventory) {
            this.socket = socket;
            this.inventory = inventory;
        }

        @Override
        public void run() {
            try (
                BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()));
                PrintWriter writer = new PrintWriter(socket.getOutputStream(), true)
            ) {
                writer.println("CONNECT_OK|Welcome to the Decentralized Enterprise Network System.");
                String clientCommand;

                while ((clientCommand = reader.readLine()) != null) {
                    String[] tokens = clientCommand.split("\\|");
                    String action = tokens[0].toUpperCase();

                    switch (action) {
                        case "LIST":
                            StringBuilder listBuilder = new StringBuilder("DATA");
                            inventory.values().forEach(book -> listBuilder.append("|").append(book.toString()));
                            writer.println(listBuilder.toString());
                            break;

                        case "BORROW":
                            if (tokens.length < 2) { writer.println("ERROR|Missing Item ID."); break; }
                            NetworkBook targetBook = inventory.get(tokens[1]);
                            if (targetBook == null) {
                                writer.println("ERROR|Item signature not found in central registry.");
                            } else if (targetBook.borrowItem()) {
                                writer.println("SUCCESS|Item " + tokens[1] + " successfully locked and checked out.");
                            } else {
                                writer.println("REJECTED|Transaction denied. Item is locked by another node.");
                            }
                            break;

                        case "RETURN":
                            if (tokens.length < 2) { writer.println("ERROR|Missing Item ID."); break; }
                            NetworkBook returnBook = inventory.get(tokens[1]);
                            if (returnBook == null) {
                                writer.println("ERROR|Item not recognized.");
                            } else {
                                returnBook.returnItem();
                                writer.println("SUCCESS|Item " + tokens[1] + " returned to active cluster storage.");
                            }
                            break;

                        case "QUIT":
                            writer.println("GOODBYE|Terminating endpoint session.");
                            return;

                        default:
                            writer.println("ERROR|Command paradigm unverified.");
                    }
                }
            } catch (IOException e) {
                System.err.println("[SERVER WORKER] Connection dropping ungracefully: " + e.getMessage());
            } finally {
                try {
                    socket.close();
                    System.out.println("[SERVER WORKER] Port interface safely reclaimed.");
                } catch (IOException e) {
                    System.err.println("[SERVER WORKER] Interface close fault.");
                }
            }
        }
    }
}

// ==========================================
// 4. REMOTE WORKSTATION CLIENT TERMINAL
// ==========================================
class RemoteLibraryClient {
    private static final String HOST = "127.0.0.1";
    private static final int PORT = 8085;

    public void connect() {
        try (
            Socket socket = new Socket(HOST, PORT);
            BufferedReader networkReader = new BufferedReader(new InputStreamReader(socket.getInputStream()));
            PrintWriter networkWriter = new PrintWriter(socket.getOutputStream(), true);
            Scanner terminalScanner = new Scanner(System.in)
        ) {
            // Confirm network synchronization handshake response
            System.out.println("[NET STATUS] " + networkReader.readLine());
            boolean interactionLoop = true;

            while (interactionLoop) {
                System.out.println("\n--- CLUSTER CONSOLE LINK ---");
                System.out.println("Commands: [1] LIST | [2] BORROW <id> | [3] RETURN <id> | [4] QUIT");
                System.out.print("Execute Protocol Token: ");
                String choice = terminalScanner.nextLine().trim();

                switch (choice) {
                    case "1":
                        networkWriter.println("LIST");
                        parseServerPayload(networkReader.readLine());
                        break;
                    case "2":
                        System.out.print("Target Item Key ID: ");
                        String bId = terminalScanner.nextLine().trim();
                        networkWriter.println("BORROW|" + bId);
                        System.out.println("[RESPONSE] " + networkReader.readLine());
                        break;
                    case "3":
                        System.out.print("Target Item Key ID: ");
                        String rId = terminalScanner.nextLine().trim();
                        networkWriter.println("RETURN|" + rId);
                        System.out.println("[RESPONSE] " + networkReader.readLine());
                        break;
                    case "4":
                        networkWriter.println("QUIT");
                        System.out.println("[RESPONSE] " + networkReader.readLine());
                        interactionLoop = false;
                        break;
                    default:
                        System.out.println("Local Validation Warning: Unrecognized workflow selection.");
                }
            }
        } catch (IOException e) {
            System.err.println("[NET ERROR] Could not bind interface pipe to node: " + e.getMessage());
        }
    }

    private void parseServerPayload(String rawPayload) {
        if (rawPayload == null) return;
        String[] parts = rawPayload.split("\\|");
        if (parts[0].equals("DATA")) {
            System.out.println("\n--- SYNCHRONIZED STORAGE SYSTEM INDEX ---");
            for (int i = 1; i < parts.length; i++) {
                System.out.println(" > " + parts[i]);
            }
        } else {
            System.out.println("[SERVER REPLY] " + rawPayload);
        }
    }
}

// ==========================================
// 5. BOOTSTRAP SYSTEM RUNTIME CONTROL
// ==========================================
public class Main {
    public static void main(String[] args) throws InterruptedException {
        // System parameter triggers either Server Node mode or Client Node Mode
        if (args.length > 0 && args[0].equalsIgnoreCase("server")) {
            new CentralLibraryServer().start();
        } else if (args.length > 0 && args[0].equalsIgnoreCase("client")) {
            new RemoteLibraryClient().connect();
        } else {
            // Default: Spin up server thread and twin parallel client connections on a single JVM machine instantly for manual sandbox testing
            System.out.println("[SYSTEM] No boot mode specified. Initializing Local Mock Cluster Sandbox...");
            
            Thread serverThread = new Thread(() -> new CentralLibraryServer().start());
            serverThread.start();
            
            // Allow thread scheduler a brief initialization slice
            Thread.sleep(1000); 
            
            System.out.println("\n[SYSTEM] Booting Client Node Terminal Interface:");
            new RemoteLibraryClient().connect();
        }
    }
}
