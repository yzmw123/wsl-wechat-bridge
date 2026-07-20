import importlib.machinery
import importlib.util
import pathlib
import sys
import unittest


SCRIPT_PATH = pathlib.Path(__file__).parents[1] / "app" / "linux" / "bin" / "wsl-app-badge-notify-watch"
LOADER = importlib.machinery.SourceFileLoader("wsl_app_badge_notify_watch", str(SCRIPT_PATH))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
LOADER.exec_module(MODULE)


class BadgeDetectionTests(unittest.TestCase):
    def make_image(self, components):
        width, height = 120, 80
        pixels = [(245, 245, 245, 255)] * (width * height)

        for x0, y0, box_width, box_height, digit in components:
            for y in range(y0, y0 + box_height):
                for x in range(x0, x0 + box_width):
                    pixels[y * width + x] = (225, 73, 73, 255)

            if digit:
                digit_x = x0 + box_width // 2
                for y in range(y0 + 2, y0 + box_height - 2):
                    pixels[y * width + digit_x] = (222, 222, 222, 255)

        return MODULE.ImageRGBA(width, height, pixels)

    def test_numeric_badge_with_light_digit_notifies(self):
        analysis = MODULE.analyze_unread_badges(self.make_image([(40, 20, 14, 15, True)]))

        self.assertTrue(analysis.should_notify)
        self.assertEqual(len(analysis.numeric_badges), 1)
        self.assertGreaterEqual(analysis.numeric_badges[0].white_pixels, MODULE.MIN_DIGIT_PIXELS)

    def test_plain_dot_same_size_does_not_notify(self):
        analysis = MODULE.analyze_unread_badges(self.make_image([(40, 20, 14, 15, False)]))

        self.assertFalse(analysis.should_notify)
        self.assertEqual(len(analysis.numeric_badges), 0)
        self.assertEqual(len(analysis.plain_dots), 1)

    def test_small_plain_dot_does_not_notify(self):
        analysis = MODULE.analyze_unread_badges(self.make_image([(40, 20, 8, 8, False)]))

        self.assertFalse(analysis.should_notify)
        self.assertEqual(len(analysis.plain_dots), 1)


if __name__ == "__main__":
    unittest.main()
