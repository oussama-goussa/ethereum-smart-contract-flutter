import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'contract_linking.dart';

class HelloUI extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Hello World!",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.black12,
      ),
      body: Consumer<ContractLinking>(
        builder: (context, contractLink, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[50]!,
                  Colors.grey[100]!,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: contractLink.isLoading
                        ? _buildLoadingState()
                        : _buildContentState(context, contractLink),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        SizedBox(height: 24),
        Text(
          "Connecting to Blockchain",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Please wait while we establish connection",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildContentState(BuildContext context, ContractLinking contractLink) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Titre
        Text(
          "Current Name",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8),

        // Display name container
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                "Hello,",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Text(
                contractLink.deployedName,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue[700],
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(height: 32),

        // Input section
        Text(
          "Set Your Name",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16),

        // Input field
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: "Enter your name",
            labelStyle: TextStyle(color: Colors.grey[600]),
            hintText: "e.g., John Doe",
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            prefixIcon: Icon(
              Icons.edit_outlined,
              color: Colors.grey[600],
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 20),

        // Primary action button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                contractLink.setName(_nameController.text.trim());
                _nameController.clear();
                _showSnackbar(context, "Updating The Name...");
              }
            },
            child: Text(
              "Set Name",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: Colors.blue.withOpacity(0.3),
            ),
          ),
        ),
        
        // Ajout d'un espace pour les messages d'état
        SizedBox(height: 20),
        
        // Affichage des messages d'état
        if (contractLink.isTransactionPending)
          _buildTransactionStatus(contractLink),
        
        if (contractLink.errorMessage.isNotEmpty)
          _buildErrorMessage(contractLink.errorMessage),
        
        SizedBox(height: 20),

        // Info text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "This DApp interacts with a smart contract on the blockchain. "
            "Each update requires a transaction confirmation.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // Bouton de rafraîchissement
        SizedBox(height: 10),
        TextButton(
          onPressed: () {
            contractLink.refresh();
            _showSnackbar(context, "Refreshing...");
          },
          child: Text(
            "Refresh",
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionStatus(ContractLinking contractLink) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              contractLink.transactionStatus,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }
}