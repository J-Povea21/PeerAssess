import 'dart:async';

import 'package:f_clean_template/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../group/domain/models/group_member.dart';
import '../../domain/models/assessment.dart';
import '../../domain/models/criteria.dart';
import '../../domain/models/criteria_score.dart';
import '../../domain/models/evaluation.dart';
import '../viewmodels/evaluation_controller.dart';

class EvaluationFormPage extends StatefulWidget {
  final Assessment assessment;
  final List<GroupMember> peers;
  final List<Criteria> criteria;
  final String evaluatorId;

  const EvaluationFormPage({
    super.key,
    required this.assessment,
    required this.peers,
    required this.criteria,
    required this.evaluatorId,
  });

  @override
  State<EvaluationFormPage> createState() => _EvaluationFormPageState();
}

class _EvaluationFormPageState extends State<EvaluationFormPage> {
  final EvaluationController controller = Get.find();

  int _currentPeerIndex = 0;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  // scores[peerId][criteriaId] = selectedScore
  final Map<String, Map<String, double?>> _scores = {};

  static final _scoreDescriptions = {
    2.0: 'Necesita mejorar',
    3.0: 'Adecuado',
    4.0: 'Bueno',
    5.0: 'Excelente',
  };

  static const _criteriaDescriptions = {
    'Puntualidad': 'Asistencia y puntualidad a sesiones',
    'Contribuciones': 'Aportes al trabajo del equipo',
    'Compromiso': 'Responsabilidad con tareas y roles',
    'Actitud': 'Disposición y actitud hacia el equipo',
  };

  @override
  void initState() {
    super.initState();
    for (final peer in widget.peers) {
      _scores[peer.id] = {};
      for (final c in widget.criteria) {
        _scores[peer.id]![c.id!] = null;
      }
    }
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    final deadline = widget.assessment.deadline;
    if (deadline == null) return;

    _remaining = deadline.difference(DateTime.now());
    if (_remaining.isNegative) {
      _onExpired();
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final left = deadline.difference(now);
      if (left.isNegative) {
        _countdownTimer?.cancel();
        _onExpired();
      } else {
        setState(() => _remaining = left);
      }
    });
  }

  void _onExpired() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El tiempo de evaluación ha expirado'),
        duration: Duration(seconds: 3),
      ),
    );
    Get.back();
  }

  String _formatRemaining(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  GroupMember get _currentPeer => widget.peers[_currentPeerIndex];

  bool get _allScoresSelected {
    for (final peer in widget.peers) {
      for (final c in widget.criteria) {
        if (_scores[peer.id]?[c.id!] == null) return false;
      }
    }
    return true;
  }

  bool get _currentPeerComplete {
    for (final c in widget.criteria) {
      if (_scores[_currentPeer.id]?[c.id!] == null) return false;
    }
    return true;
  }

  void _nextPeer() {
    if (_currentPeerIndex < widget.peers.length - 1) {
      setState(() => _currentPeerIndex++);
    }
  }

  void _previousPeer() {
    if (_currentPeerIndex > 0) {
      setState(() => _currentPeerIndex--);
    }
  }

  Future<void> _submit() async {
    if (!_allScoresSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todas las calificaciones')),
      );
      return;
    }

    final evaluations = <Evaluation>[];
    final scoresPerEvaluation = <List<CriteriaScore>>[];

    for (final peer in widget.peers) {
      evaluations.add(Evaluation(
        assessmentId: widget.assessment.id!,
        evaluatorId: widget.evaluatorId,
        evaluatedId: peer.id,
      ));

      final peerScores = widget.criteria.map((c) {
        return CriteriaScore(
          criteriaId: c.id!,
          score: _scores[peer.id]![c.id!]!,
        );
      }).toList();

      scoresPerEvaluation.add(peerScores);
    }

    final success = await controller.submitAllEvaluations(
        evaluations, scoresPerEvaluation);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evaluaciones enviadas correctamente')),
      );
      Get.back();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al enviar las evaluaciones')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final peer = _currentPeer;
    final isLastPeer = _currentPeerIndex == widget.peers.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Evaluar a ${peer.fullName}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.beige,
              Colors.white,
              AppColors.rose.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildProgressHeader(peer),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPeerAvatar(peer),
                  const SizedBox(height: 24),
                  ...widget.criteria.map((c) => _buildCriteriaCard(peer, c)),
                ],
              ),
            ),
            _buildBottomButtons(isLastPeer),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader(GroupMember peer) {
    final progress = (_currentPeerIndex + 1) / widget.peers.length;
    final isUrgent = _remaining.inMinutes < 5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Compañero ${_currentPeerIndex + 1} de ${widget.peers.length}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              if (widget.assessment.deadline != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isUrgent
                        ? AppColors.salmon.withValues(alpha: 0.12)
                        : AppColors.olive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer,
                          size: 14,
                          color: isUrgent ? AppColors.salmon : AppColors.olive),
                      const SizedBox(width: 4),
                      Text(
                        _formatRemaining(_remaining),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              isUrgent ? AppColors.salmon : AppColors.olive,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(AppColors.olive),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerAvatar(GroupMember peer) {
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.olive,
          child: Text(
            peer.initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          peer.fullName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildCriteriaCard(GroupMember peer, Criteria criteria) {
    final selectedScore = _scores[peer.id]?[criteria.id!];
    final description = _criteriaDescriptions[criteria.name] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            criteria.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [2.0, 3.0, 4.0, 5.0].map((score) {
              final isSelected = selectedScore == score;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _scores[peer.id]![criteria.id!] = score;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.olive
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.olive
                            : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      score.toInt().toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (selectedScore != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                _scoreDescriptions[selectedScore]!,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.olive.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomButtons(bool isLastPeer) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentPeerIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPeer,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.olive),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Anterior',
                    style: TextStyle(color: AppColors.olive, fontSize: 16)),
              ),
            ),
          if (_currentPeerIndex > 0) const SizedBox(width: 12),
          Expanded(
            child: isLastPeer
                ? Obx(() => FilledButton(
                      onPressed: controller.isLoading.value ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.olive,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Enviar',
                              style: TextStyle(fontSize: 16)),
                    ))
                : FilledButton(
                    onPressed: _currentPeerComplete ? _nextPeer : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.olive,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Siguiente',
                        style: TextStyle(fontSize: 16)),
                  ),
          ),
        ],
      ),
    );
  }
}
