import math
from datetime import datetime

def calculate_angle(a_x, a_y, b_x, b_y, c_x, c_y):
    # Calculates angle at B formed by A-B-C
    ba_x = a_x - b_x
    ba_y = a_y - b_y
    bc_x = c_x - b_x
    bc_y = c_y - b_y

    dot_product = ba_x * bc_x + ba_y * bc_y
    mag_ba = math.sqrt(ba_x * ba_x + ba_y * ba_y)
    mag_bc = math.sqrt(bc_x * bc_x + bc_y * bc_y)

    if mag_ba == 0 or mag_bc == 0:
        return 180.0

    cos_angle = max(-1.0, min(1.0, dot_product / (mag_ba * mag_bc)))
    return math.acos(cos_angle) * (180.0 / math.pi)

class SquatAnalyzer:
    def __init__(self):
        self.state = "UP"
        self.total_reps = 0
        self.correct_reps = 0
        self.incorrect_reps = 0
        self.baseline_heel_y = -1.0
        self.rep_start_time = None
        
        # Error flags for current rep
        self.depth_valid = False
        self.heel_lift_error = False
        self.forward_lean_error = False
        self.knee_over_toe_error = False
        
        self.previous_knee_angle = 180.0
        
    def reset_rep_errors(self):
        self.depth_valid = False
        self.heel_lift_error = False
        self.forward_lean_error = False
        self.knee_over_toe_error = False

    def get_accuracy(self):
        if self.total_reps == 0:
            return 0.0
        return (self.correct_reps / self.total_reps) * 100.0

    def process_frame(self, data: dict) -> dict:
        # Extract variables
        hip_x, hip_y = data["hip_x"], data["hip_y"]
        knee_x, knee_y = data["knee_x"], data["knee_y"]
        ankle_x, ankle_y = data["ankle_x"], data["ankle_y"]
        heel_y = data["heel_y"]
        toe_x = data["toe_x"]
        shoulder_x, shoulder_y = data["shoulder_x"], data["shoulder_y"]
        
        knee_vis = data.get("knee_visibility", 1.0)
        hip_vis = data.get("hip_visibility", 1.0)
        ankle_vis = data.get("ankle_visibility", 1.0)
        
        is_facing_right = data.get("is_facing_right", True)
        timestamp_str = data.get("timestamp", datetime.now().isoformat())
        
        # 1. Minimum visibility check
        if knee_vis < 0.6 or hip_vis < 0.6 or ankle_vis < 0.6:
            return self._build_response(False, None, "none", 180.0)

        # 2. Calculate angles
        raw_knee_angle = calculate_angle(hip_x, hip_y, knee_x, knee_y, ankle_x, ankle_y)
        torso_angle = calculate_angle(shoulder_x, shoulder_y, hip_x, hip_y, knee_x, knee_y)
        
        # 3. Angle smoothing filter
        knee_angle = 0.7 * self.previous_knee_angle + 0.3 * raw_knee_angle
        self.previous_knee_angle = knee_angle
        
        # 4. Heel baseline smoothing
        if self.baseline_heel_y < 0 or self.state == "UP":
            if self.baseline_heel_y < 0:
                self.baseline_heel_y = heel_y
            else:
                self.baseline_heel_y = 0.95 * self.baseline_heel_y + 0.05 * heel_y

        rep_detected = False
        rep_quality = "correct"
        feedback_message = ""

        # 5. State Machine
        if self.state == "UP":
            if knee_angle < 105.0:
                self.state = "DOWN"
                self.rep_start_time = datetime.fromisoformat(timestamp_str.replace("Z", "+00:00"))
                self.reset_rep_errors()
                
        elif self.state == "DOWN":
            # Validation Rules
            
            # Depth Validation
            if knee_angle < 110.0:
                self.depth_valid = True
                
            # Heel Lift Detection
            if abs(heel_y - self.baseline_heel_y) > 0.04 and knee_angle < 120.0:
                self.heel_lift_error = True
                
            # Torso Lean Detection
            if torso_angle < 35.0:
                self.forward_lean_error = True
                
            # Knee Over Toe Detection
            if is_facing_right:
                if knee_x > toe_x + 0.04:
                    self.knee_over_toe_error = True
            else:
                if knee_x < toe_x - 0.04:
                    self.knee_over_toe_error = True

            # Transition to UP
            if knee_angle > 150.0:
                rep_detected = True
                self.total_reps += 1
                
                # Speed Validation
                rep_duration = 0.0
                if self.rep_start_time:
                    end_time = datetime.fromisoformat(timestamp_str.replace("Z", "+00:00"))
                    rep_duration = (end_time - self.rep_start_time).total_seconds()
                
                # Rep Quality Classification
                if not self.depth_valid:
                    rep_quality = "shallow"
                    feedback_message = "Go lower"
                elif self.heel_lift_error:
                    rep_quality = "heelLift"
                    feedback_message = "Keep your heels down"
                elif self.forward_lean_error:
                    rep_quality = "forwardLean"
                    feedback_message = "Keep your chest up"
                elif self.knee_over_toe_error:
                    rep_quality = "kneeOverToe"
                    feedback_message = "Do not push knees too forward"
                elif rep_duration < 0.5:
                    rep_quality = "tooFast"
                    feedback_message = "Slow down"
                elif rep_duration > 8.0:
                    rep_quality = "tooSlow"
                    feedback_message = "Maintain rhythm"
                else:
                    rep_quality = "correct"
                    feedback_message = "Good squat"

                if rep_quality == "correct":
                    self.correct_reps += 1
                else:
                    self.incorrect_reps += 1
                    
                self.state = "UP"

        return self._build_response(rep_detected, rep_quality, feedback_message, knee_angle)

    def _build_response(self, rep_detected, rep_quality, feedback_message, current_angle):
        return {
            "rep_detected": rep_detected,
            "rep_quality": rep_quality if rep_detected else None,
            "total_reps": self.total_reps,
            "correct_reps": self.correct_reps,
            "incorrect_reps": self.incorrect_reps,
            "accuracy": self.get_accuracy(),
            "feedback_message": feedback_message if rep_detected else None,
            
            # State fields to keep UI synchronized easily
            "state": self.state,
            "depth_valid": self.depth_valid,
            "heel_lift_error": self.heel_lift_error,
            "forward_lean_error": self.forward_lean_error,
            "knee_over_toe_error": self.knee_over_toe_error,
            "knee_angle": current_angle
        }
