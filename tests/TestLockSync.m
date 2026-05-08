classdef TestLockSync < matlab.unittest.TestCase
    % Tests for lock and sync commands with mock packages.

    properties
        TempDir
        OrigHome
        OrigDir
        OrigPath
        MockIndexFile
        MockPkgDir
        ProjectDir
    end

    methods (TestMethodSetup)
        function setupTest(testCase)
            testCase.TempDir = fullfile(tempdir, "tbx_test_" + string(randi(99999)));
            mkdir(testCase.TempDir);
            testCase.OrigHome = getenv("TBXMANAGER_HOME");
            testCase.OrigDir = pwd;
            testCase.OrigPath = path;
            setenv("TBXMANAGER_HOME", testCase.TempDir);

            % Ensure tbxmanager stays on path after cd
            tbxFile = which("tbxmanager");
            if ~isempty(tbxFile)
                addpath(fileparts(tbxFile));
            end

            testCase.MockPkgDir = fullfile(testCase.TempDir, "mock_packages");
            mkdir(testCase.MockPkgDir);
            testCase.MockIndexFile = fullfile(testCase.TempDir, "mock_index.json");

            % Initialize tbxmanager
            evalc('tbxmanager("help")');

            % Create mock packages and index
            testCase.createMockPackages();
            testCase.createMockIndex();

            % Point tbxmanager to local mock index
            srcUrl = char("file://" + replace(string(testCase.MockIndexFile), "\", "/"));
            evalc('tbxmanager("source", "remove", "https://marekwadinger.github.io/tbxmanager-registry/index.json")');
            evalc('tbxmanager("source", "add", srcUrl)');

            % Create project directory with tbxmanager.json
            testCase.ProjectDir = fullfile(testCase.TempDir, "project");
            mkdir(testCase.ProjectDir);
            projData = struct();
            projData.name = 'myproject';
            projData.version = '0.1.0';
            projData.dependencies = struct('testpkg2', '>=1.0');
            fid = fopen(fullfile(testCase.ProjectDir, "tbxmanager.json"), 'w');
            fprintf(fid, '%s', jsonencode(projData));
            fclose(fid);

            % Teardowns run LIFO
            testCase.addTeardown(@() rmdir(testCase.TempDir, 's'));
            testCase.addTeardown(@() cd(testCase.OrigDir));
            testCase.addTeardown(@() path(testCase.OrigPath));
            testCase.addTeardown(@() setenv("TBXMANAGER_HOME", testCase.OrigHome));
        end
    end

    methods (Access = private)
        function createMockPackages(testCase)
            % Create testpkg1 v1.0.0
            d = fullfile(testCase.MockPkgDir, "testpkg1_v1");
            mkdir(d);
            fid = fopen(fullfile(d, "testpkg1_hello.m"), 'w');
            fprintf(fid, 'function testpkg1_hello()\ndisp(''hello from testpkg1 v1'');\nend\n');
            fclose(fid);
            zip(fullfile(testCase.MockPkgDir, "testpkg1-1.0.0-all.zip"), '*', d);

            % Create testpkg2 v2.0.0 (depends on testpkg1)
            d2 = fullfile(testCase.MockPkgDir, "testpkg2_v2");
            mkdir(d2);
            fid = fopen(fullfile(d2, "testpkg2_hello.m"), 'w');
            fprintf(fid, 'function testpkg2_hello()\ndisp(''hello from testpkg2 v2'');\nend\n');
            fclose(fid);
            zip(fullfile(testCase.MockPkgDir, "testpkg2-2.0.0-all.zip"), '*', d2);
        end

        function hash = computeSha256(~, filepath)
            md = java.security.MessageDigest.getInstance("SHA-256");
            fid = fopen(filepath, 'r');
            while ~feof(fid)
                chunk = fread(fid, 65536, '*uint8');
                if ~isempty(chunk)
                    md.update(chunk);
                end
            end
            fclose(fid);
            hashBytes = md.digest();
            hexChars = '0123456789abcdef';
            hash = blanks(length(hashBytes) * 2);
            for i = 1:length(hashBytes)
                b = typecast(int8(hashBytes(i)), 'uint8');
                hash((i-1)*2 + 1) = hexChars(bitshift(b, -4) + 1);
                hash((i-1)*2 + 2) = hexChars(bitand(b, 15) + 1);
            end
        end

        function s = jsonEscape(~, s0)
            s = char(s0);
            s = strrep(s, '\', '\\');
            s = strrep(s, '"', '\"');
        end

        function createMockIndex(testCase)
            d = testCase.MockPkgDir;

            h1v1 = testCase.computeSha256(fullfile(d, "testpkg1-1.0.0-all.zip"));
            h2v2 = testCase.computeSha256(fullfile(d, "testpkg2-2.0.0-all.zip"));

            u1v1 = char("file://" + replace(string(fullfile(d, "testpkg1-1.0.0-all.zip")), "\", "/"));
            u2v2 = char("file://" + replace(string(fullfile(d, "testpkg2-2.0.0-all.zip")), "\", "/"));

            fmt = @(s) strrep(testCase.jsonEscape(s), '%', '%%');
            vfmt = @(u,h,r) sprintf('{"matlab":">=R2022a","dependencies":{},"platforms":{"all":{"url":"%s","sha256":"%s"}},"released":"%s"}', ...
                fmt(u), fmt(h), fmt(r));
            v2dep = sprintf('{"matlab":">=R2022a","dependencies":{"testpkg1":">=1.0"},"platforms":{"all":{"url":"%s","sha256":"%s"}},"released":"2025-03-01"}', ...
                fmt(u2v2), fmt(h2v2));

            json = [...
                '{' ...
                    '"index_version":1,' ...
                    '"generated":"2026-01-01T00:00:00Z",' ...
                    '"packages":{' ...
                        '"testpkg1":{"name":"testpkg1","description":"Test package 1","license":"MIT","authors":["Test"],"latest":"1.0.0",' ...
                        '"versions":{"1.0.0":' vfmt(u1v1, h1v1, '2025-01-01') '}},' ...
                        '"testpkg2":{"name":"testpkg2","description":"Test package 2","license":"MIT","authors":["Test"],"latest":"2.0.0",' ...
                        '"versions":{"2.0.0":' v2dep '}}' ...
                    '}' ...
                '}'];

            fid = fopen(testCase.MockIndexFile, 'w');
            fprintf(fid, '%s', json);
            fclose(fid);
        end
    end

    methods (Test)

        % --- lock errors ---

        function testLockNoProjectFile(testCase)
            emptyDir = fullfile(testCase.TempDir, "empty_project");
            mkdir(emptyDir);
            cd(emptyDir);
            out = evalc('tbxmanager("lock")');
            testCase.verifyTrue(contains(out, "tbxmanager.json") || contains(out, "No"), ...
                'Should report missing project file');
        end

        function testLockCreatesLockFile(testCase)
            cd(testCase.ProjectDir);
            evalc('tbxmanager("lock")');
            lockFile = fullfile(testCase.ProjectDir, "tbxmanager.lock");
            testCase.verifyTrue(isfile(lockFile), 'Lock file should be created');
        end

        function testLockResolvesPackage(testCase)
            cd(testCase.ProjectDir);
            evalc('tbxmanager("lock")');
            lockFile = fullfile(testCase.ProjectDir, "tbxmanager.lock");
            lockData = jsondecode(fileread(lockFile));
            testCase.verifyTrue(isfield(lockData, 'packages'), 'Lock should have packages field');
            testCase.verifyTrue(isfield(lockData.packages, 'testpkg2'), ...
                'Lock should contain testpkg2');
        end

        function testLockResolvesWithDeps(testCase)
            cd(testCase.ProjectDir);
            evalc('tbxmanager("lock")');
            lockFile = fullfile(testCase.ProjectDir, "tbxmanager.lock");
            lockData = jsondecode(fileread(lockFile));
            testCase.verifyTrue(isfield(lockData.packages, 'testpkg1'), ...
                'Lock should contain dependency testpkg1');
            testCase.verifyTrue(isfield(lockData.packages, 'testpkg2'), ...
                'Lock should contain testpkg2');
        end

        function testLockContainsSha256(testCase)
            cd(testCase.ProjectDir);
            evalc('tbxmanager("lock")');
            lockFile = fullfile(testCase.ProjectDir, "tbxmanager.lock");
            lockData = jsondecode(fileread(lockFile));
            pkg = lockData.packages.testpkg2;
            testCase.verifyTrue(isfield(pkg, 'resolved') && isfield(pkg.resolved, 'sha256'), ...
                'Lock entry should have sha256');
            testCase.verifyEqual(strlength(string(pkg.resolved.sha256)), 64, ...
                'SHA256 should be 64 hex characters');
        end

        function testLockContainsUrl(testCase)
            cd(testCase.ProjectDir);
            evalc('tbxmanager("lock")');
            lockFile = fullfile(testCase.ProjectDir, "tbxmanager.lock");
            lockData = jsondecode(fileread(lockFile));
            pkg = lockData.packages.testpkg2;
            testCase.verifyTrue(isfield(pkg, 'resolved') && isfield(pkg.resolved, 'url'), ...
                'Lock entry should have url');
            testCase.verifyTrue(strlength(string(pkg.resolved.url)) > 0, ...
                'URL should not be empty');
        end

        function testLockGenerationFailure(testCase)
            % Project with unsatisfiable constraint → lock rethrows, caller sees error
            noDepDir = fullfile(testCase.TempDir, "project_nodeps");
            mkdir(noDepDir);
            nodepData = struct('name', 'nodeps', 'version', '0.1.0');
            fid = fopen(fullfile(noDepDir, "tbxmanager.json"), 'w');
            fprintf(fid, '%s', jsonencode(nodepData));
            fclose(fid);
            cd(noDepDir);
            threw = false;
            try
                evalc('tbxmanager("lock")');
            catch
                threw = true;
            end
            % Either threw OR printed a failure message (both are acceptable)
            testCase.verifyTrue(threw, 'lock should throw on generation failure');
        end

        % --- sync errors ---

        function testSyncNoLockFile(testCase)
            emptyDir = fullfile(testCase.TempDir, "empty_sync");
            mkdir(emptyDir);
            cd(emptyDir);
            out = evalc('tbxmanager("sync")');
            testCase.verifyTrue(contains(out, "lock") || contains(out, "No"), ...
                'Should report missing lock file');
        end

        function testSyncNoPackagesField(testCase)
            % Lock file exists but has no 'packages' field
            syncDir = fullfile(testCase.TempDir, "sync_nopkgs");
            mkdir(syncDir);
            cd(syncDir);
            fid = fopen(fullfile(syncDir, "tbxmanager.lock"), 'w');
            fprintf(fid, '{"lockfile_version":1,"generated":"2026-01-01T00:00:00Z","requires":{}}');
            fclose(fid);
            out = evalc('tbxmanager("sync")');
            testCase.verifyTrue(contains(out, "No packages") || contains(out, "lock"), ...
                'Should report no packages in lock file');
        end

        function testSyncInstallsFromLock(testCase)
            cd(testCase.ProjectDir);
            evalc('tbxmanager("lock")');
            evalc('tbxmanager("sync")');
            testCase.verifyTrue( ...
                isfolder(fullfile(testCase.TempDir, "packages", "testpkg2")), ...
                'testpkg2 should be installed after sync');
            testCase.verifyTrue( ...
                isfolder(fullfile(testCase.TempDir, "packages", "testpkg1")), ...
                'testpkg1 (dependency) should be installed after sync');
        end

        function testSyncSkipsUpToDate(testCase)
            cd(testCase.ProjectDir);
            evalc('tbxmanager("lock")');
            evalc('tbxmanager("sync")');
            out = evalc('tbxmanager("sync")');
            testCase.verifyTrue(contains(out, "up to date"), ...
                'Second sync should report up to date');
        end

        function testLockThenSyncRoundtrip(testCase)
            cd(testCase.ProjectDir);
            evalc('tbxmanager("lock")');
            evalc('tbxmanager("sync")');
            out = evalc('tbxmanager("list")');
            testCase.verifyTrue(contains(out, "testpkg2"), ...
                'List should show testpkg2 after lock+sync');
            testCase.verifyTrue(contains(out, "testpkg1"), ...
                'List should show testpkg1 after lock+sync');
        end

        function testSyncDisablesNonProjectPackages(testCase)
            % Install both testpkg1 and testpkg2, then sync with a lock that
            % only contains testpkg1. testpkg2 must stay on disk but be
            % disabled (removed from path) since it is not in the project lock.
            evalc('tbxmanager("install", "testpkg1")');
            evalc('tbxmanager("install", "testpkg2")');

            simpleDir = fullfile(testCase.TempDir, "simple_project");
            mkdir(simpleDir);
            projData = struct('name', 'simple', 'version', '0.1.0', ...
                              'dependencies', struct('testpkg1', '>=1.0'));
            fid = fopen(fullfile(simpleDir, "tbxmanager.json"), 'w');
            fprintf(fid, '%s', jsonencode(projData));
            fclose(fid);

            cd(simpleDir);
            evalc('tbxmanager("lock")');
            evalc('tbxmanager("sync")');

            % Disk: testpkg2 must still be installed
            testCase.verifyTrue(isfolder(fullfile(testCase.TempDir, "packages", "testpkg2")), ...
                'testpkg2 must remain on disk — sync never deletes global packages');
            % Path: testpkg2 must be disabled (not in enabled.json)
            enabled = jsondecode(fileread(fullfile(testCase.TempDir, "state", "enabled.json")));
            testCase.verifyFalse(isfield(enabled, 'testpkg2'), ...
                'testpkg2 must be disabled from path after sync');
        end

        function testSyncVersionMismatch(testCase)
            % Install testpkg1 (v1.0.0 in mock index), then create a lock file
            % that requires testpkg1@2.0.0 (different version) using the same zip.
            % Sync detects instVer ~= reqVer → hits L1833 (toInstall branch).
            evalc('tbxmanager("install", "testpkg1")');

            pkgFile = fullfile(testCase.MockPkgDir, "testpkg1-1.0.0-all.zip");
            hash = testCase.computeSha256(pkgFile);
            pkgUrl = char("file://" + replace(string(pkgFile), "\", "/"));

            lockPkg.version = "2.0.0";   % differs from installed 1.0.0
            lockPkg.resolved.url = pkgUrl;
            lockPkg.resolved.sha256 = hash;
            lockPkg.dependencies = struct();

            lockData.lockfile_version = 1;
            lockData.generated = "2026-01-01T00:00:00Z";
            lockData.requires = struct("testpkg1", ">=1.0");
            lockData.packages.testpkg1 = lockPkg;

            mismatchDir = fullfile(testCase.TempDir, "mismatch_proj");
            mkdir(mismatchDir);
            cd(mismatchDir);
            fid = fopen(fullfile(mismatchDir, "tbxmanager.lock"), 'w');
            fprintf(fid, '%s', jsonencode(lockData));
            fclose(fid);

            evalc('tbxmanager("sync")');
            testCase.verifyTrue(isfolder(fullfile(testCase.TempDir, "packages", "testpkg1", "2.0.0")), ...
                'testpkg1 should be installed at lock-specified version 2.0.0');
        end

        function testSyncNoDependenciesField(testCase)
            % Create a lock file where the package entry has no "dependencies" field.
            % Covers the else branch in main_sync that assigns pkg.dependencies = struct().
            syncDir = fullfile(testCase.TempDir, "sync_nodeps");
            mkdir(syncDir);

            pkgFile = fullfile(testCase.MockPkgDir, "testpkg1-1.0.0-all.zip");
            hash = testCase.computeSha256(pkgFile);
            pkgUrl = char("file://" + replace(string(pkgFile), "\", "/"));

            % Build lock entry WITHOUT "dependencies" field
            lockPkg.version = "1.0.0";
            lockPkg.resolved.url = pkgUrl;
            lockPkg.resolved.sha256 = hash;
            % Intentionally omit "dependencies" field to hit the else branch (L1920)

            lockData.lockfile_version = 1;
            lockData.generated = "2026-01-01T00:00:00Z";
            lockData.requires = struct("testpkg1", ">=1.0");
            lockData.packages.testpkg1 = lockPkg;

            cd(syncDir);
            fid = fopen(fullfile(syncDir, "tbxmanager.lock"), 'w');
            fprintf(fid, '%s', jsonencode(lockData));
            fclose(fid);

            evalc('tbxmanager("sync")');
            testCase.verifyTrue(isfolder(fullfile(testCase.TempDir, "packages", "testpkg1")), ...
                'Package should be installed from lock without dependencies field');
        end

        % --- add: error cases ---

        function testAddNoArgs(testCase)
            cd(testCase.ProjectDir);
            out = evalc('tbxmanager("add")');
            testCase.verifyTrue(contains(out, 'Usage') || contains(out, 'add'), ...
                'Should show usage when no args');
        end

        function testAddNoProjectFile(testCase)
            emptyDir = fullfile(testCase.TempDir, 'add_noproj');
            mkdir(emptyDir);
            cd(emptyDir);
            out = evalc('tbxmanager("add", "testpkg1")');
            testCase.verifyTrue(contains(out, 'tbxmanager.json') || contains(out, 'init'), ...
                'Should error when no project file');
        end

        % --- add: happy paths ---

        function testAddWritesToProjectFile(testCase)
            % Fresh project with no deps
            projDir = fullfile(testCase.TempDir, 'add_proj');
            mkdir(projDir);
            proj.name = 'testproject'; proj.version = '0.1.0'; proj.dependencies = struct();
            fid = fopen(fullfile(projDir, 'tbxmanager.json'), 'w');
            fprintf(fid, '%s', jsonencode(proj)); fclose(fid);
            cd(projDir);
            evalc('tbxmanager("add", "testpkg1")');
            data = jsondecode(fileread(fullfile(projDir, 'tbxmanager.json')));
            testCase.verifyTrue(isfield(data.dependencies, 'testpkg1'), ...
                'add should write package into tbxmanager.json dependencies');
        end

        function testAddWithConstraintWritten(testCase)
            projDir = fullfile(testCase.TempDir, 'add_constr_proj');
            mkdir(projDir);
            proj.name = 'testproject'; proj.version = '0.1.0'; proj.dependencies = struct();
            fid = fopen(fullfile(projDir, 'tbxmanager.json'), 'w');
            fprintf(fid, '%s', jsonencode(proj)); fclose(fid);
            cd(projDir);
            evalc('tbxmanager("add", "testpkg1@>=1.0")');
            data = jsondecode(fileread(fullfile(projDir, 'tbxmanager.json')));
            testCase.verifyTrue(isfield(data.dependencies, 'testpkg1'), ...
                'add should write package with constraint');
            testCase.verifyEqual(string(data.dependencies.testpkg1), ">=1.0", ...
                'Constraint should be stored correctly');
        end

        function testAddInstallsPackage(testCase)
            projDir = fullfile(testCase.TempDir, 'add_install_proj');
            mkdir(projDir);
            proj.name = 'testproject'; proj.version = '0.1.0'; proj.dependencies = struct();
            fid = fopen(fullfile(projDir, 'tbxmanager.json'), 'w');
            fprintf(fid, '%s', jsonencode(proj)); fclose(fid);
            cd(projDir);
            evalc('tbxmanager("add", "testpkg1")');
            testCase.verifyTrue(isfolder(fullfile(testCase.TempDir, 'packages', 'testpkg1')), ...
                'add should install the package via lock+sync');
        end

        % --- remove: error cases ---

        function testRemoveNoArgs(testCase)
            cd(testCase.ProjectDir);
            out = evalc('tbxmanager("remove")');
            testCase.verifyTrue(contains(out, 'Usage') || contains(out, 'remove'), ...
                'Should show usage when no args');
        end

        function testRemoveNoProjectFile(testCase)
            emptyDir = fullfile(testCase.TempDir, 'remove_noproj');
            mkdir(emptyDir);
            cd(emptyDir);
            out = evalc('tbxmanager("remove", "testpkg1")');
            testCase.verifyTrue(contains(out, 'tbxmanager.json') || contains(out, 'init'), ...
                'Should error when no project file');
        end

        function testRemoveNotInDeps(testCase)
            cd(testCase.ProjectDir);
            out = evalc('tbxmanager("remove", "nonexistent_pkg")');
            testCase.verifyTrue(contains(out, 'not') || contains(out, 'warning') || contains(out, 'Warning'), ...
                'Should warn when package not in dependencies');
        end

        % --- remove: happy path ---

        function testRemoveDeletesFromProjectFile(testCase)
            % Set up project with testpkg1 as dependency
            projDir = fullfile(testCase.TempDir, 'remove_proj');
            mkdir(projDir);
            proj.name = 'testproject'; proj.version = '0.1.0';
            proj.dependencies.testpkg1 = '>=1.0';
            fid = fopen(fullfile(projDir, 'tbxmanager.json'), 'w');
            fprintf(fid, '%s', jsonencode(proj)); fclose(fid);
            cd(projDir);
            evalc('tbxmanager("lock")');
            evalc('tbxmanager("sync")');
            % Now remove it
            evalc('tbxmanager("remove", "testpkg1")');
            data = jsondecode(fileread(fullfile(projDir, 'tbxmanager.json')));
            testCase.verifyFalse(isfield(data.dependencies, 'testpkg1'), ...
                'remove should delete package from tbxmanager.json dependencies');
        end

        function testRemoveKeepsGlobalPackage(testCase)
            % Full round-trip: add testpkg1, then remove from project.
            % The global install must persist — remove only edits tbxmanager.json.
            % Use 'tbxmanager uninstall' to remove from the global store.
            projDir = fullfile(testCase.TempDir, 'remove_uninstall_proj');
            mkdir(projDir);
            proj.name = 'testproject'; proj.version = '0.1.0';
            proj.dependencies.testpkg1 = '>=1.0';
            fid = fopen(fullfile(projDir, 'tbxmanager.json'), 'w');
            fprintf(fid, '%s', jsonencode(proj)); fclose(fid);
            cd(projDir);
            evalc('tbxmanager("lock")');
            evalc('tbxmanager("sync")');
            testCase.verifyTrue(isfolder(fullfile(testCase.TempDir, 'packages', 'testpkg1')), ...
                'testpkg1 should be installed before remove');
            evalc('tbxmanager("remove", "testpkg1")');
            testCase.verifyTrue(isfolder(fullfile(testCase.TempDir, 'packages', 'testpkg1')), ...
                'testpkg1 must remain globally installed after project remove');
            % Confirm it was removed from tbxmanager.json
            projJson = jsondecode(fileread(fullfile(projDir, 'tbxmanager.json')));
            testCase.verifyFalse(isfield(projJson.dependencies, 'testpkg1'), ...
                'testpkg1 should be removed from tbxmanager.json dependencies');
        end

        % --- contextual hints ---

        function testInstallHintWhenProjectExists(testCase)
            % install from project dir should show the add tip
            cd(testCase.ProjectDir);
            out = evalc('tbxmanager("install", "testpkg1")');
            testCase.verifyTrue(contains(out, 'add') || contains(out, 'Tip'), ...
                'install should hint about add when tbxmanager.json present');
        end

        function testInstallNoHintWithoutProject(testCase)
            noJsonDir = fullfile(testCase.TempDir, 'no_proj_hint');
            mkdir(noJsonDir);
            cd(noJsonDir);
            out = evalc('tbxmanager("install", "testpkg1")');
            % Tip line should NOT appear without a project file
            testCase.verifyFalse(contains(out, 'tbxmanager add'), ...
                'install should not show add tip when no tbxmanager.json present');
        end

        % --- check: match / mismatch ---

        function testCheckMatchesLock(testCase)
            cd(testCase.ProjectDir);
            evalc('tbxmanager("lock")');
            evalc('tbxmanager("sync")');
            out = evalc('tbxmanager("check")');
            % tbx_printSuccess prints "All packages match lock file."
            testCase.verifyTrue(contains(out, 'match') || contains(out, char(10003)), ...
                'check should report all packages match after lock+sync');
        end

        function testCheckDetectsMismatch(testCase)
            cd(testCase.ProjectDir);
            evalc('tbxmanager("lock")');
            evalc('tbxmanager("sync")');
            % Corrupt the lock to require a non-installed version
            lockFile = fullfile(testCase.ProjectDir, "tbxmanager.lock");
            lockData = jsondecode(fileread(lockFile));
            lockData.packages.testpkg2.version = '9.9.9';
            fid = fopen(lockFile, 'w');
            fprintf(fid, '%s', jsonencode(lockData));
            fclose(fid);
            out = evalc('tbxmanager("check")');
            testCase.verifyTrue(contains(out, '9.9.9') || contains(out, 'requires') || contains(out, char(10007)), ...
                'check should report version mismatch');
        end

        % --- tree: installed packages ---

        function testTreeShowsInstalled(testCase)
            evalc('tbxmanager("install", "testpkg2")');  % also installs testpkg1 as dep
            out = evalc('tbxmanager("tree")');
            testCase.verifyTrue(contains(out, 'testpkg2'), ...
                'tree should show installed root package');
        end

        function testTreeShowsDeps(testCase)
            evalc('tbxmanager("install", "testpkg2")');
            out = evalc('tbxmanager("tree")');
            testCase.verifyTrue(contains(out, 'testpkg1'), ...
                'tree should show dependency testpkg1 under testpkg2');
        end

    end
end
