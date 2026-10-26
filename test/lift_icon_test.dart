import 'package:flutter_test/flutter_test.dart';
import 'package:plate_calc/ui/widgets/lift_icon.dart';

void main() {
  test('movimientos base tienen su pictograma', () {
    expect(liftPoseFor('Deadlift'), LiftPose.deadlift);
    expect(liftPoseFor('Snatch'), LiftPose.snatch);
    expect(liftPoseFor('Clean'), LiftPose.clean);
    expect(liftPoseFor('Jerk'), LiftPose.jerk);
  });

  test('movimientos del usuario se reconocen por palabras clave', () {
    expect(liftPoseFor('Back Squat'), LiftPose.squat);
    expect(liftPoseFor('Sentadilla'), LiftPose.squat);
    expect(liftPoseFor('Front Squat'), LiftPose.clean);
    expect(liftPoseFor('Bench Press'), LiftPose.bench);
    expect(liftPoseFor('Press banca'), LiftPose.bench);
    expect(liftPoseFor('Développé couché'), LiftPose.bench);
    expect(liftPoseFor('Shoulder Press'), LiftPose.press);
    expect(liftPoseFor('Clean & Jerk'), LiftPose.jerk);
    expect(liftPoseFor('Peso muerto rumano'), LiftPose.deadlift);
    expect(liftPoseFor('Arranque'), LiftPose.snatch);
    expect(liftPoseFor('Hip Thrust'), LiftPose.generic);
  });
}
