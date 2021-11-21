<?php

namespace App\Providers;

use DB;
use Exception;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     *
     * @return void
     */
    public function register(): void
    {
        if ($this->app->environment('local')) {
            $this->app->register(\Laravel\Telescope\TelescopeServiceProvider::class);
            $this->app->register(TelescopeServiceProvider::class);
        }
    }

    /**
     * Bootstrap any application services.
     *
     * @return void
     */
    public function boot(): void
    {
        Queue::looping(
            static function () {
                $check = false;
                while (!$check) {
                    try {
                        DB::connection()->getPdo();
                        $check = true;
                    } catch (Exception) {
                        sleep(5);
                    }
                }
                $bootedFile = storage_path('app/booted');
                if (!file_exists($bootedFile)) {
                    @touch($bootedFile);
                    @chmod($bootedFile, 0777);
                }
            }
        );
    }
}
