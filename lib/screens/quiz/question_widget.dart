import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/question_model.dart';

class QuestionWidget extends StatelessWidget {
  final Question question;
  final int? selectedOptionIndex;
  final Function(int selectedIndex) onOptionSelected;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.selectedOptionIndex,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Daha derin bir siyah-lacivert geçişi
        color: const Color(0xFF1E222D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)), // Çok ince bir çerçeve
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Soru Başlığı ve İkon
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: kPrimaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                "Risk Analizi",
                style: TextStyle(
                  color: kPrimaryColor.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question.text,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 32),
          // Seçenekler
          ...question.options.asMap().entries.map((entry) {
            final int index = entry.key;
            final String option = entry.value;

            return _buildOptionButton(
              text: option,
              optionIndex: index,
              isSelected: selectedOptionIndex == index,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required String text,
    required int optionIndex,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E222D).withOpacity(0.9),// hafif saydam
          borderRadius: BorderRadius.circular(24),
          // Seçilince parlayan (neon) efekti
          border: Border.all(color: kPrimaryColor.withOpacity(0.2),width:1.5),

          boxShadow: isSelected
              ? [
            BoxShadow(
              color: kPrimaryColor.withOpacity(0.05),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            )
          ]
              : [],
        ),
        child: InkWell(
          onTap: () => onOptionSelected(optionIndex),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                // Seçilen şıkkın yanına ufak bir check işareti
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}