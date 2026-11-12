#!/usr/bin/env python3
"""
Unit tests for GTA8 Multi-touch Gesture Recognition Logic.
Tests multi-finger gestures, pinch vs scroll classification, kinetic scrolling, and tap timing.
"""
import math
import unittest

def classify_two_finger_gesture(d_start, d_curr, dy_avg, dx_avg, pinch_threshold=60.0):
    """
    Classifies a two-finger gesture into 'pinch', 'vscroll', or 'hscroll'.
    """
    delta_dist = abs(d_curr - d_start)
    if delta_dist > pinch_threshold and delta_dist > max(abs(dy_avg), abs(dx_avg)) * 0.8:
        return "pinch"
    if abs(dy_avg) >= abs(dx_avg):
        return "vscroll"
    return "hscroll"

def compute_euclidean_distance(p1, p2):
    return math.hypot(p1[0] - p2[0], p1[1] - p2[1])

def calculate_kinetic_steps(initial_velocity, friction=0.88, min_velocity=1.0):
    steps = []
    v = initial_velocity
    while abs(v) > min_velocity:
        steps.append(round(v))
        v *= friction
    return steps

class TestGTA8Gestures(unittest.TestCase):
    def test_euclidean_distance(self):
        p1 = (100, 200)
        p2 = (400, 600)
        self.assertAlmostEqual(compute_euclidean_distance(p1, p2), 500.0)

    def test_scroll_classification(self):
        # Two fingers moving down parallel by 120 pixels
        p1_start = (300, 400)
        p2_start = (500, 400)
        d_start = compute_euclidean_distance(p1_start, p2_start)  # 200

        p1_end = (300, 520)
        p2_end = (500, 520)
        d_end = compute_euclidean_distance(p1_end, p2_end)      # 200

        gesture = classify_two_finger_gesture(d_start, d_end, dy_avg=120, dx_avg=0)
        self.assertEqual(gesture, "vscroll")

    def test_pinch_classification(self):
        # Two fingers spreading apart (pinch-to-zoom)
        p1_start = (400, 400)
        p2_start = (500, 400)
        d_start = compute_euclidean_distance(p1_start, p2_start)  # 100

        p1_end = (300, 400)
        p2_end = (650, 400)
        d_end = compute_euclidean_distance(p1_end, p2_end)      # 350

        gesture = classify_two_finger_gesture(d_start, d_end, dy_avg=10, dx_avg=20)
        self.assertEqual(gesture, "pinch")

    def test_kinetic_decay(self):
        steps = calculate_kinetic_steps(initial_velocity=50.0, friction=0.85)
        self.assertTrue(len(steps) > 5)
        self.assertEqual(steps[0], 50)
        self.assertTrue(steps[-1] >= 1)
        # Verify strictly decreasing magnitude
        for i in range(1, len(steps)):
            self.assertLessEqual(steps[i], steps[i-1])

if __name__ == "__main__":
    unittest.main()
