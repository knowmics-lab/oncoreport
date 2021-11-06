<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Jobs;

use App\Constants;
use App\Exceptions\IgnoredException;
use App\Exceptions\ProcessingJobException;
use App\Models\Job as JobModel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Auth;
use Throwable;

class Request implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    /**
     * Delete the job if its models no longer exist.
     *
     * @var bool
     */
    public bool $deleteWhenMissingModels = true;

    public int $timeout = 0;

    /**
     * Create a new job instance.
     *
     * @param  \App\Models\Job  $model
     */
    public function __construct(protected JobModel $model)
    {
    }

    /**
     * Execute the job.
     *
     * @return void
     */
    public function handle(): void
    {
        $jobProcessor = null;
        try {
            if ($this->model->shouldNotRun()) {  // job is being processed (or has been processed) by another thread.
                $this->delete();

                return;
            }
            $this->model->log = '';
            $this->model->setStatus(Constants::PROCESSING);
            $this->delete();
            $jobProcessor = Types\Factory::get($this->model);
            if (!$jobProcessor->isInputValid()) {
                throw new ProcessingJobException('Job input format is not valid');
            }
            Auth::login($this->model->owner);
            $jobProcessor->handle();
            Auth::logout();
            $this->model->setStatus(Constants::COMPLETED);
        } catch (Throwable $e) {
            if (!($e instanceof IgnoredException)) {
                $this->model->appendLog('Error: ' . $e);
            }
            $this->model->setStatus(Constants::FAILED);
            if ($jobProcessor instanceof Types\AbstractJob) {
                $jobProcessor->cleanupOnFail();
            }
            $this->fail($e);
        }
    }
}
