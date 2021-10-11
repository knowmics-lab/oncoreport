<?php
/**
 * Oncoreport Web Service
 *
 * @author S. Alaimo, Ph.D. <alaimos at gmail dot com>
 */

namespace App\Models;

use App\Constants;
use App\Jobs\Types\Factory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;
use Storage;

class Job extends Model
{

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'sample_code',
        'name',
        'job_type',
        'status',
        'job_parameters',
        'job_output',
        'log',
        'owner_id',
        'patient_id',
    ];

    /**
     * The model's default values for attributes.
     *
     * @var array
     */
    protected $attributes = [
        'job_type'       => Constants::READY,
        'job_parameters' => "{}",
        'job_output'     => "{}",
        'log'            => '',
        'patient_id'     => null,
    ];

    /**
     * The attributes that should be cast to native types.
     *
     * @var array
     */
    protected $casts = [
        'job_parameters' => 'array',
        'job_output'     => 'array',
    ];

    /**
     * Scope a query to filter for job_type.
     * If a job is a group then it uses the type of the first grouped job.
     *
     * @param  \Illuminate\Database\Eloquent\Builder  $query
     * @param  \App\Models\Patient  $patient
     *
     * @return \Illuminate\Database\Eloquent\Builder
     */
    public function scopeByPatient(Builder $query, Patient $patient): Builder
    {
        return $query->whereNotNull('patient_id')->where('patient_id', $patient->id);
    }

    /**
     * Scope a query to filter for job_type.
     * If a job is a group then it uses the type of the first grouped job.
     *
     * @param  \Illuminate\Database\Eloquent\Builder  $query
     * @param  string  $type
     *
     * @return \Illuminate\Database\Eloquent\Builder
     */
    public function scopeByType(Builder $query, string $type): Builder
    {
        return $query->where('job_type', $type);
    }

    /**
     * Returns a default name if its value is null
     *
     * @param  string|null  $value
     *
     * @return string
     */
    public function getNameAttribute(?string $value): string
    {
        return $value ?? ($this->readableJobType() . ' Job of ' . $this->created_at->diffForHumans());
    }

    /**
     * Returns the readable job type
     *
     * @return string
     */
    public function readableJobType(): string
    {
        return Factory::displayName($this);
    }

    /**
     * Returns a default sample code if its value is null
     *
     * @param  string|null  $value
     *
     * @return string
     */
    public function getSampleCodeAttribute(?string $value): string
    {
        return $value ?? ('' . $this->id);
    }

    /**
     * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
     */
    public function patient(): BelongsTo
    {
        return $this->belongsTo(Patient::class);
    }

    /**
     * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
     */
    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    /**
     * Set the status attribute.
     *
     * @param  string  $value
     */
    public function setStatusAttribute(string $value): void
    {
        if (!in_array($value, Constants::JOB_STATES, true)) {
            $value = Constants::READY;
        }
        $this->attributes['status'] = $value;
    }

    /**
     * Set the log attribute.
     *
     * @param  string  $value
     */
    public function setLogAttribute(string $value): void
    {
        $aLines = explode("\n", $value);
        $value = implode(
            "\n",
            array_map(
                static function ($line) {
                    $line = preg_replace('/\033\[([0-9;]+)m/i', '', $line);
                    if (!str_contains($line, "\r")) {
                        return $line;
                    }
                    $arr = array_filter(explode("\r", $line));
                    $n = count($arr);
                    if ($n > 0) {
                        return last($arr);
                    }

                    return '';
                },
                $aLines
            )
        );
        $this->attributes['log'] = $value;
    }

    /**
     * Returns the absolute path of the job storage directory
     *
     * @return string
     */
    public function getAbsoluteJobDirectory(): string
    {
        return $this->absoluteJobPath($this->getJobDirectory());
    }

    /**
     * Returns the absolute path of a job path
     *
     * @param  string  $path
     *
     * @return string
     */
    public function absoluteJobPath(string $path): string
    {
        return storage_path('app/public/' . $path);
    }

    /**
     * Returns the path of the job storage directory
     *
     * @return string
     */
    public function getJobDirectory(): string
    {
        $path = 'jobs/' . $this->id;
        $disk = Storage::disk('public');
        if (!$disk->exists($path)) {
            $disk->makeDirectory($path);
            @chmod($this->absoluteJobPath($path), 0777);
        }

        return $path;
    }

    /**
     * Returns the absolute path of a temporary file in the job directory
     *
     * @param  string  $prefix
     * @param  string  $suffix
     *
     * @return string
     */
    public function getJobTempFileAbsolute(string $prefix = '', string $suffix = ''): string
    {
        return $this->absoluteJobPath($this->getJobTempFile($prefix, $suffix));
    }

    /**
     * Returns the path of a temporary file in the job directory
     *
     * @param  string  $prefix
     * @param  string  $suffix
     *
     * @return string
     */
    public function getJobTempFile(string $prefix = '', string $suffix = ''): string
    {
        $filename = preg_replace('/[\W]+/', '', uniqid($prefix, true)) . $suffix;

        return $this->getJobDirectory() . '/' . $filename;
    }

    /**
     * Returns the absolute path of a file in the job directory
     *
     * @param  string  $prefix
     * @param  string  $suffix
     *
     * @return string
     */
    public function getJobFileAbsolute(string $prefix = '', string $suffix = ''): string
    {
        return $this->absoluteJobPath($this->getJobFile($prefix, $suffix));
    }

    /**
     * Returns the path of a file in the job directory
     *
     * @param  string  $prefix
     * @param  string  $suffix
     *
     * @return string
     */
    public function getJobFile(string $prefix = '', string $suffix = ''): string
    {
        return $this->getJobDirectory() . '/' . $prefix . Str::slug($this->name) . $suffix;
    }

    /**
     * Delete the job directory
     *
     * @return bool
     */
    public function deleteJobDirectory(): bool
    {
        return Storage::disk('public')->deleteDirectory($this->getJobDirectory());
    }

    /**
     * Checks if the current job can be modified
     *
     * @return bool
     */
    public function canBeModified(): bool
    {
        return $this->status === Constants::READY;
    }

    /**
     * Checks if the current job can be deleted
     *
     * @return bool
     */
    public function canBeDeleted(): bool
    {
        return in_array($this->status, [Constants::READY, Constants::COMPLETED, Constants::FAILED], true);
    }

    /**
     * Checks if the current job has completed
     *
     * @return bool
     */
    public function hasCompleted(): bool
    {
        return in_array($this->status, [Constants::COMPLETED, Constants::FAILED], true);
    }

    /**
     * Checks if the current job should run or not.
     * Only queued jobs should run.
     *
     * @return bool
     */
    public function shouldNotRun(): bool
    {
        return in_array($this->status, [Constants::PROCESSING, Constants::COMPLETED, Constants::FAILED], true);
    }

    /**
     * Set a new status value and save this model
     *
     * @param $newStatus
     *
     * @return $this
     */
    public function setStatus($newStatus): self
    {
        $this->update(['status' => $newStatus]);

        return $this;
    }

    /**
     * Set the value of one or more output data.
     * If $parameter is an associative array sets multiple parameters at the same time.
     *
     * @param  array|string  $parameter
     * @param  null|mixed  $value
     *
     * @return $this
     */
    public function setOutput($parameter, $value = null): self
    {
        $tmp = $this->job_output;
        if (!is_array($tmp)) {
            $tmp = [];
        }
        if ($value === null && is_array($parameter)) {
            foreach ($parameter as $p => $v) {
                data_set($tmp, $p, $v);
            }
        } else {
            data_set($tmp, $parameter, $value);
        }
        $this->job_output = $tmp;

        return $this;
    }

    /**
     * Get the value of an output data
     *
     * @param  string|array|null  $parameter
     * @param  mixed  $default
     *
     * @return mixed
     */
    public function getOutput($parameter = null, $default = null): mixed
    {
        if ($parameter === null) {
            return $this->job_output;
        }
        if (is_array($parameter)) {
            $slice = [];
            foreach ($parameter as $key) {
                $slice[$key] = data_get($this->job_output, $key, $default);
            }

            return $slice;
        }

        return data_get($this->job_output, $parameter, $default);
    }

    /**
     * Set the value of a parameter
     *
     * @param  string  $parameter
     * @param  mixed  $value
     *
     * @return $this
     */
    public function setParameter(string $parameter, $value): self
    {
        $tmp = $this->job_parameters;
        data_set($tmp, $parameter, $value);
        $this->job_parameters = $tmp;

        return $this;
    }

    /**
     * Set parameters of this job
     *
     * @param  array  $parameters
     *
     * @return $this
     */
    public function setParameters(array $parameters): self
    {
        $this->job_parameters = [];

        return $this->addParameters($parameters);
    }

    /**
     * Add parameters to this job
     *
     * @param  array  $parameters
     *
     * @return $this
     */
    public function addParameters(array $parameters): self
    {
        $tmp = $this->job_parameters;
        foreach ($parameters as $param => $value) {
            data_set($tmp, $param, $value);
        }
        $this->job_parameters = $tmp;

        return $this;
    }

    /**
     * Get the value of a parameter
     *
     * @param  string|array|null  $parameter
     * @param  mixed  $default
     *
     * @return mixed
     */
    public function getParameter($parameter = null, $default = null): mixed
    {
        if ($parameter === null) {
            return $this->job_parameters;
        }
        if (is_array($parameter)) {
            $slice = [];
            foreach ($parameter as $key) {
                $slice[$key] = data_get($this->job_parameters, $key, $default);
            }

            return $slice;
        }

        return data_get($this->job_parameters, $parameter, $default);
    }

    /**
     * Append text to the log
     *
     * @param  string  $text
     * @param  bool  $appendNewLine
     * @param  bool  $commit
     */
    public function appendLog(string $text, bool $appendNewLine = true, bool $commit = true): void
    {
        if ($appendNewLine) {
            $text .= PHP_EOL;
        }
        // echo $text; // @TODO FOR DEBUG ONLY
        $this->log .= $text;
        if ($commit) {
            $this->save();
        }
    }

}
