import 'package:gymrank/features/championships/domain/entities/championship_entity.dart';

abstract interface class ChampionshipRepository {
  Stream<List<ChampionshipEntity>> watchByCoach(String coachId);
}
