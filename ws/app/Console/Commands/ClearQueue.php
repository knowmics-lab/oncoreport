<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Console\Commands;

use App\Constants;
use App\Models\Job;
use Illuminate\Console\Command;
use Queue;

class ClearQueue extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'queue:clear';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Clears the queue before closing the docker container';


    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle(): int
    {
        while (($j = Queue::pop()) !== null) {
            $j->delete();
        }
        $this->call('queue:flush');
        foreach (Job::whereStatus(Constants::QUEUED)->get() as $job) {
            $job->status = Constants::READY;
            $job->save();
        }
        foreach (Job::whereStatus(Constants::PROCESSING)->get() as $job) {
            $job->status = Constants::FAILED;
            $job->appendLog('Job failed since queue was cleared!', true, false);
            $job->save();
        }

        return 0;
    }
}
