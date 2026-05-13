"""Monkey-patch mkdocs livereload for Python 3.14 compatibility.

mkdocs 1.6.1's _build_loop uses a Condition.wait_for + nested wait pattern
that silently deadlocks on Python 3.14. This replaces it with a simple
wait loop that works correctly.

Remove this file when mkdocs fixes the issue upstream.
"""

import logging
import sys
import traceback

import mkdocs.livereload as lr

log = logging.getLogger("mkdocs.livereload")


def _build_loop_py314(self):
    while True:
        with self._rebuild_cond:
            while not self._want_rebuild and not self._shutdown:
                self._rebuild_cond.wait(timeout=0.5)
            if self._shutdown:
                break
            log.info("Detected file changes")
            # Brief pause for rapid successive saves
            self._rebuild_cond.wait(timeout=self.build_delay)
            self._wanted_epoch = lr._timestamp()
            self._want_rebuild = False

        try:
            self.builder()
        except Exception as e:
            if isinstance(e, SystemExit):
                print(e, file=sys.stderr)
            else:
                traceback.print_exc()
            log.error(
                "An error happened during the rebuild."
                " The server will appear stuck until build errors are resolved."
            )
            continue

        with self._epoch_cond:
            log.info("Reloading browsers")
            self._visible_epoch = self._wanted_epoch
            self._epoch_cond.notify_all()


if sys.version_info >= (3, 14):
    lr.LiveReloadServer._build_loop = _build_loop_py314
