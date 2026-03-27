import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/file_service.dart';
import '../services/excel_service.dart';
import '../core/grade_parser_factory.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/custom_button.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedFile;
  bool _isUploading = false;
  
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final media = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Grades'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              final isWide = constraints.maxWidth > 600;
              final horizontalPadding = isWide ? media.size.width * 0.2 : 16.0;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                child: Column(
                  children: [
                    _buildUploadArea(constraints),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 24),
                      _buildFileInfo(),
                    ],
                    const Spacer(),
                    if (_selectedFile != null && !_isUploading)
                      _buildProcessButton(context, state),
                    if (_isUploading) const LoadingIndicator(),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildUploadArea(BoxConstraints constraints) {
    final isWide = constraints.maxWidth > 600;
    final areaHeight = isWide ? 260.0 : constraints.maxHeight * 0.25;
    final iconSize = isWide ? 80.0 : 56.0;
    final fontSize = isWide ? 18.0 : 15.0;
    final subFontSize = isWide ? 14.0 : 11.0;
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        height: areaHeight.clamp(140.0, 320.0),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_upload,
                size: iconSize,
                color: Colors.grey[400],
              ),
              SizedBox(height: isWide ? 20 : 14),
              Text(
                'Tap to upload Excel file',
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isWide ? 10 : 7),
              Text(
                'Supported formats: .xlsx, .xls',
                style: TextStyle(
                  fontSize: subFontSize,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFileInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFile!.path.split('/').last,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(_selectedFile!.lengthSync() / 1024).toStringAsFixed(2)} KB',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              setState(() {
                _selectedFile = null;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildProcessButton(BuildContext context, AppState state) {
    return CustomButton(
      text: 'Process Grades',
      icon: Icons.calculate,
      onPressed: () => _processFile(context, state),
    );
  }
  
  Future<void> _pickFile() async {
    final file = await FileService.pickExcelFile();
    if (file != null) {
      setState(() {
        _selectedFile = file;
      });
    }
  }
  
  Future<void> _processFile(BuildContext context, AppState state) async {
    if (_selectedFile == null) return;
    
    setState(() => _isUploading = true);
    
    try {
      final parser = GradeParserFactory.getParser('excel');
      final validation = parser.validateFile(_selectedFile!.path);
      
      if (!validation['valid']) {
        throw Exception(validation['error']);
      }
      
      final students = await parser.parseGrades(
        filePath: _selectedFile!.path,
        totalSubjects: state.totalSubjects,
        maxGrade: state.maxGrade,
      );
      
      state.setStudents(students);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully processed ${students.length} students'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}