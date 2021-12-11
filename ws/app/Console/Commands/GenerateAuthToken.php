<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Console\Commands;

use App\Actions\Api\User\CreateUserToken;
use App\Models\User;
use Exception;
use Illuminate\Console\Command;

class GenerateAuthToken extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'auth:token {user} {--json}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Generate a new authentication token for an user';

    /**
     * Execute the console command.
     *
     * @return int
     * @throws \JsonException
     */
    public function handle(): int
    {
        $user = $this->argument('user');
        $json = $this->option('json');
        try {
            $userObject = User::whereEmail($user)->first();
            if ($userObject === null) {
                if ($json) {
                    $this->line(
                        json_encode(
                            [
                                'error' => 101,
                                'data'  => 'User not found. Please specify a valid user.',
                            ],
                            JSON_THROW_ON_ERROR
                        )
                    );
                } else {
                    $this->error('User not found. Please specify a valid user.');
                }

                return 101;
            }

            $token = (new CreateUserToken())->create($userObject, 'command-line-token-');

            $displayedToken = explode('|', $token->plainTextToken, 2)[1];

            if ($json) {
                $this->line(
                    json_encode(
                        [
                            'error' => 0,
                            'data'  => $displayedToken,
                        ],
                        JSON_THROW_ON_ERROR
                    )
                );
            } else {
                $this->info('Token generated. The new token is: ' . $displayedToken);
            }
        } catch (Exception $e) {
            if ($json) {
                $this->line(
                    json_encode(
                        [
                            'error' => 102,
                            'data'  => 'An error occurred: ' . $e->getMessage(),
                        ],
                        JSON_THROW_ON_ERROR
                    )
                );
            } else {
                $this->error('An error occurred: ' . $e->getMessage());
            }

            return 102;
        }

        return 0;
    }
}
