import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

class ContractLinking extends ChangeNotifier {
  // Configuration
  static const String _rpcUrl = "http://127.0.0.1:7545";
  static const String _wsUrl = "ws://127.0.0.1:7545";
  static const String _privateKey = "0x72a3e41b56ffe5331344b0c848afe3ff2a86ff222cce4a2a1b439d33dd03c05e";
  static const int _chainId = 1337; // Ganache default

  // State
  late Web3Client _client;
  bool _isLoading = true;
  bool _isTransactionPending = false;
  String _transactionStatus = "";
  late ContractAbi _contractAbi;
  late EthereumAddress _contractAddress;
  late Credentials _credentials;
  late DeployedContract _contract;
  String _deployedName = "Loading...";
  String _lastTransactionHash = "";
  String _errorMessage = "";

  // Getters
  bool get isLoading => _isLoading;
  bool get isTransactionPending => _isTransactionPending;
  String get transactionStatus => _transactionStatus;
  String get deployedName => _deployedName;
  String get lastTransactionHash => _lastTransactionHash;
  String get errorMessage => _errorMessage;
  String get contractAddress => _contractAddress.hex;

  ContractLinking() {
    _initializeConnection();
  }

  Future<void> _initializeConnection() async {
    try {
      _setLoading(true);
      _clearError();

      print("Initializing blockchain connection...");
      
      // Initialize Web3 client
      _client = Web3Client(
        _rpcUrl,
        http.Client(),
        socketConnector: () {
          return IOWebSocketChannel.connect(_wsUrl).cast<String>();
        },
      );
      
      await _loadContractAbi();
      await _initializeCredentials();
      await _connectToDeployedContract();
      await _fetchCurrentName();
      
      print("Blockchain connection established successfully!");
    } catch (e) {
      _setError("Failed to connect to blockchain: $e");
      print("Connection error: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadContractAbi() async {
    try {
      print("Loading contract ABI...");
      
      // Load compiled contract JSON
      String abiString = await rootBundle.loadString("src/artifacts/HelloWorld.json");
      var jsonAbi = jsonDecode(abiString);
      
      // Parse ABI
      _contractAbi = ContractAbi.fromJson(
        jsonEncode(jsonAbi["abi"]), 
        "HelloWorld"
      );
      
      // Find contract address from networks
      var networks = jsonAbi["networks"];
      
      // Try common network IDs
      List<String> networkIds = ["1337", "5777", "1", "3", "4", "5", "42"];
      
      for (var networkId in networkIds) {
        if (networks.containsKey(networkId)) {
          _contractAddress = EthereumAddress.fromHex(networks[networkId]["address"]);
          print("Contract address (network $networkId): ${_contractAddress.hex}");
          return;
        }
      }
      
      // If no common network found, try the first available
      if (networks.isNotEmpty) {
        var firstNetwork = networks.keys.first;
        _contractAddress = EthereumAddress.fromHex(networks[firstNetwork]["address"]);
        print("Contract address (network $firstNetwork): ${_contractAddress.hex}");
      } else {
        throw Exception("No deployed networks found in contract ABI");
      }
    } catch (e) {
      print("ABI loading error: $e");
      rethrow;
    }
  }

  Future<void> _initializeCredentials() async {
    try {
      print("Initializing credentials...");
      
      // Create credentials from private key
      _credentials = EthPrivateKey.fromHex(_privateKey);
      
      // Verify account address
      final address = await _credentials.extractAddress();
      final balance = await _client.getBalance(address);
      
      print("Account initialized");
      print("   Address: ${address.hex}");
      print("   Balance: ${balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(4)} ETH");
      
    } catch (e) {
      print("Credentials error: $e");
      rethrow;
    }
  }

  Future<void> _connectToDeployedContract() async {
    try {
      print("Connecting to deployed contract...");
      
      // Create deployed contract instance
      _contract = DeployedContract(_contractAbi, _contractAddress);
      
      print("Contract connection established");
      
    } catch (e) {
      print("Contract connection error: $e");
      rethrow;
    }
  }

  Future<void> _fetchCurrentName() async {
    try {
      print("Fetching current name from contract...");
      
      // Call the yourName() function
      final function = _contract.function('yourName');
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [],
      );
      
      // Process result
      if (result.isNotEmpty) {
        _deployedName = result[0].toString();
        print("Current name: '$_deployedName'");
      } else {
        _deployedName = "No name set";
        print("No name returned from contract");
      }
      
      _clearError();
    } catch (e, stackTrace) {
      print("Name fetch error: $e");
      print("Stack trace: $stackTrace");
      _deployedName = "Error loading name";
      _setError("Failed to fetch name: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> setName(String nameToSet) async {
    try {
      if (nameToSet.isEmpty) {
        _setError("Name cannot be empty");
        return;
      }
      
      if (_isTransactionPending) {
        _setError("Please wait for the previous transaction to complete");
        return;
      }
      
      print("Setting name to: '$nameToSet'");
      
      _setTransactionPending(true);
      _setTransactionStatus("Preparing transaction...");
      _clearError();
      
      // Get account address
      final address = await _credentials.extractAddress();
      
      // Prepare transaction
      _setTransactionStatus("Estimating gas...");
      final transaction = Transaction.callContract(
        contract: _contract,
        function: _contract.function('setName'),
        parameters: [nameToSet],
        from: address,
      );
      
      // Send transaction
      _setTransactionStatus("Sending transaction...");
      _lastTransactionHash = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: _chainId,
      );
      
      print("Transaction sent! Hash: $_lastTransactionHash");
      _setTransactionStatus("Waiting for confirmation...");
      
      // Wait for transaction to be mined
      await _waitForTransactionConfirmation(_lastTransactionHash);
      
      // Fetch updated name
      _setTransactionStatus("Updating display...");
      await _fetchCurrentName();
      
      print("Name successfully updated to '$nameToSet'");
      _setTransactionStatus("Transaction completed successfully!");
      
    } catch (e, stackTrace) {
      print("Set name error: $e");
      print("Stack trace: $stackTrace");
      _setError("Failed to set name: $e");
      _setTransactionStatus("Transaction failed");
    } finally {
      await Future.delayed(Duration(seconds: 2));
      _setTransactionPending(false);
      _setTransactionStatus("");
    }
  }

  Future<void> _waitForTransactionConfirmation(String txHash) async {
    try {
      print("Waiting for transaction confirmation...");
      
      bool isConfirmed = false;
      int attempts = 0;
      const maxAttempts = 30; // 30 * 1 second = 30 seconds timeout
      
      while (!isConfirmed && attempts < maxAttempts) {
        attempts++;
        await Future.delayed(Duration(seconds: 1));
        
        try {
          final receipt = await _client.getTransactionReceipt(txHash);
          if (receipt != null) {
            isConfirmed = true;
            print("Transaction confirmed in block ${receipt.blockNumber}");
            _setTransactionStatus("Transaction confirmed!");
          }
        } catch (e) {
          // Continue waiting
        }
        
        if (attempts % 5 == 0) {
          _setTransactionStatus("Still waiting... (${attempts}s)");
        }
      }
      
      if (!isConfirmed) {
        throw Exception("Transaction confirmation timeout");
      }
      
    } catch (e) {
      print("Transaction confirmation error: $e");
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _fetchCurrentName();
  }

  // State management helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setTransactionPending(bool pending) {
    _isTransactionPending = pending;
    notifyListeners();
  }

  void _setTransactionStatus(String status) {
    _transactionStatus = status;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = "";
    notifyListeners();
  }

  // Utility methods
  Future<EtherAmount> getAccountBalance() async {
    try {
      final address = await _credentials.extractAddress();
      return await _client.getBalance(address);
    } catch (e) {
      print("Balance check error: $e");
      return EtherAmount.fromUnitAndValue(EtherUnit.wei, BigInt.zero);
    }
  }

  Future<int> getBlockNumber() async {
    try {
      return await _client.getBlockNumber();
    } catch (e) {
      print("Block number error: $e");
      return 0;
    }
  }

  void reset() {
    _deployedName = "Loading...";
    _errorMessage = "";
    _lastTransactionHash = "";
    _transactionStatus = "";
    _isLoading = true;
    _isTransactionPending = false;
    notifyListeners();
  }

  // Cleanup
  void disposeClient() {
    _client.dispose();
  }
}