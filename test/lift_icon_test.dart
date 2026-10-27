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

  test('ejercicios de Gym tienen un pictograma razonable', () {
    expect(liftPoseFor('Barbell Row'), LiftPose.row);
    expect(liftPoseFor('Seated Row'), LiftPose.row);
    expect(liftPoseFor('Romanian Deadlift'), LiftPose.deadlift);
    expect(liftPoseFor('Leg Press'), LiftPose.squat);
    expect(liftPoseFor('Dumbbell Press'), LiftPose.bench);
    expect(liftPoseFor('Chest Fly'), LiftPose.bench);
    expect(liftPoseFor('Dumbbell Shoulder Press'), LiftPose.press);
    expect(liftPoseFor('Barbell Curl'), LiftPose.curl);
    expect(liftPoseFor('Cable Crunch'), LiftPose.core);
    expect(liftPoseFor('Russian Twist'), LiftPose.core);
    expect(liftPoseFor('Triceps Pushdown'), LiftPose.generic);
  });
}
