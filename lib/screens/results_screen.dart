import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/pdf_service.dart';
import '../services/file_service.dart';
import '../widgets/grade_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_indicator.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Results'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _exportPDF(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final horizontalPadding = isWide ? constraints.maxWidth * 0.18 : 0.0;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    _buildSummaryCard(context, isWide),
                    Expanded(
                      child: _buildResultsList(context, isWide),
                    ),
                    _buildExportButtons(context, isWide),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard(BuildContext context, bool isWide) {
    final state = Provider.of<AppState>(context);
    final results = state.calculateResults();
    final classAverage = state.getClassAverage();
    return Container(
      margin: EdgeInsets.symmetric(vertical: 18, horizontal: isWide ? 0 : 16),
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: isWide ? 40 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Class Summary',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Students', results.length.toString(), Icons.people, isWide),
              _buildStatItem('Class Average', classAverage.toStringAsFixed(2), Icons.analytics, isWide),
              _buildStatItem('Subjects', state.totalSubjects.toString(), Icons.book, isWide),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, bool isWide) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF667eea), size: isWide ? 38 : 30),
        SizedBox(height: isWide ? 10 : 7),
        Text(
          value,
          style: TextStyle(fontSize: isWide ? 26 : 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: isWide ? 14 : 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
  
  Widget _buildResultsList(BuildContext context, bool isWide) {
    final state = Provider.of<AppState>(context);
    final results = state.calculateResults();
    return results.isEmpty
        ? Center(
            child: Text(
              'No results to display.',
              style: TextStyle(fontSize: isWide ? 20 : 16, color: Colors.white70),
            ),
          )
        : ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 12 : 0, vertical: 10),
            itemCount: results.length,
            separatorBuilder: (_, __) => SizedBox(height: isWide ? 18 : 10),
            itemBuilder: (context, index) {
              final entry = results.entries.elementAt(index);
              return GradeCard(
                studentName: entry.key,
                average: entry.value,
              );
            },
          );
  }
  
  Widget _buildExportButtons(BuildContext context, bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: isWide ? 32 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Export PDF',
              icon: Icons.picture_as_pdf,
              onPressed: () => _exportPDF(context),
              isOutlined: true,
            ),
          ),
          SizedBox(width: isWide ? 24 : 12),
          Expanded(
            child: CustomButton(
              text: 'New Calculation',
              icon: Icons.refresh,
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _exportPDF(BuildContext context) async {
    final state = Provider.of<AppState>(context, listen: false);
    final results = state.calculateResults();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: LoadingIndicator()),
    );
    
    try {
      final pdfService = const PdfService();
      final filePath = await pdfService.export(results: results, format: 'pdf');
      
      Navigator.pop(context);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Successful'),
          content: const Text('PDF has been generated successfully. Would you like to share it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await FileService.shareFile(filePath);
              },
              child: const Text('Share'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}