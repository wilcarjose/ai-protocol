<?php

declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| Project architecture rules
|--------------------------------------------------------------------------
|
| The rules this project adds to the kit's (`ArchitectureTest.php`, which is
| protected and never edited): one per rule of `.ai/project/ARCHITECTURE.md`
| that can be checked on the code. They run in the same gate and under the
| same bans (`.ai/RULES.md §Lista negra`).
|
| Seeded by the ai-protocol kit: once installed, it belongs to the project.
|
| Example: a feature does not use another feature's Actions.
|
|     arch('Listings does not depend on Payments')
|         ->expect('App\Actions\Listings')
|         ->not->toUse('App\Actions\Payments');
*/
