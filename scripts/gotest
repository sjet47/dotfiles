#!/usr/bin/env python3
import sys
import time
import subprocess
from typing import Iterable, Self, Optional
from rich import box
from rich.live import Live
from rich.panel import Panel
from rich.table import Table
from rich.progress import (
    Progress,
    BarColumn,
    SpinnerColumn,
    TimeElapsedColumn,
    MofNCompleteColumn,
)

FRESH_RATE = 0.1


def get_test_names(pattern: str) -> Iterable[str]:
    result = subprocess.run(["go", "test", "-list", pattern], capture_output=True)
    return filter(
        lambda line: line.startswith("Test"), result.stdout.decode("utf-8").split("\n")
    )


class Test:
    def __init__(self, name: str, start: bool = False, timeout: str = "1200s"):
        self.name: str = name
        self.timeout: str = timeout
        self._result: Optional[int] = None
        if start:
            self.start()

    def start(self) -> Self:
        cmd = ["go", "test", "-count=1", f"-timeout={self.timeout}", "-run", self.name]
        self._proc = subprocess.Popen(
            cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        return self

    def result(self) -> Optional[int]:
        return self._result

    def poll(self) -> Optional[int]:
        self._result = self._proc.poll()
        return self.result()


class TestTask:
    def __init__(self, progress: Progress, test_name: str, start: bool = False):
        self.progress = progress
        self.test_name = test_name
        self.test = Test(test_name, start=start)
        self.task_id = self.progress.add_task(test_name, total=1, status="")
        self.done = False

    def poll(self) -> bool:
        if self.done or self.test.result() is not None:
            return False

        result = self.test.poll()
        if result is None:
            return False
        elif result == 0:  # ok
            self.progress.update(
                self.task_id,
                advance=1,
                description="[green]" + self.test.name,
                status="✅",
            )
        elif result == 1:  # FAIL
            self.progress.update(
                self.task_id,
                advance=1,
                description="[red]" + self.test.name,
                status="❌",
            )
        else:  # Unknown
            self.progress.update(
                self.task_id,
                advance=1,
                description="[gray]" + self.test.name,
                status="🚫",
            )
        self.done = True
        return True


class OverallProgress:
    def __init__(self, tests: int):
        self.progress = Progress(
            # "{task.description}",
            TimeElapsedColumn(),
            BarColumn(),
            MofNCompleteColumn(),
        )
        self.task_id = self.progress.add_task("All Tests", total=tests)

    def advance(self, step: int):
        self.progress.advance(self.task_id, step)


class TestProgress:
    def __init__(self, *test_names: str) -> None:
        self.progress = Progress(
            SpinnerColumn(),
            "{task.description}",
            TimeElapsedColumn(),
            "{task.fields[status]}",
        )
        self.test_tasks: dict[str, TestTask] = {
            test_name: TestTask(self.progress, test_name, start=True)
            for test_name in test_names
        }

    def poll(self, overall_progress: OverallProgress):
        for _, test_task in self.test_tasks.items():
            if test_task.poll():
                overall_progress.advance(1)


def main(pattern: str):
    test_names = list(get_test_names(pattern))
    if len(test_names) == 0:
        print(f"No tests found for pattern '{pattern}'")
        return

    overall_progress = OverallProgress(len(test_names))
    test_progress = TestProgress(*test_names)

    test_table = Table().grid()
    test_table.add_row()
    test_table.add_row(test_progress.progress)
    test_table.add_row()
    test_table.add_row(overall_progress.progress)

    panel = Panel.fit(
        test_table,
        title=f"Testing {pattern}",
        border_style="red",
    )

    with Live(panel, refresh_per_second=10):
        while not overall_progress.progress.finished:
            test_progress.poll(overall_progress)
            time.sleep(FRESH_RATE)


if __name__ == "__main__":
    if len(sys.argv) == 1:
        sys.argv.append("Test") # Use "Test" to grep all tests
    main(sys.argv[1])
