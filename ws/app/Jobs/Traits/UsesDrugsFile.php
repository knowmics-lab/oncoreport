<?php

namespace App\Jobs\Traits;

use App\Models\PatientDrug;

trait UsesDrugsFile
{

    /**
     * Create a file containing all patient drugs and returns its absolute path.
     * A new file is created every time we run this function to keep the previous set of drugs.
     *
     * @return string
     */
    protected function createDrugsFile(): string
    {
        $file = $this->model->getJobTempFileAbsolute('patient_drugs_', '.txt');
        $drugIds = $this->model->patient->drugs()
                                        ->whereNull('end_date')
                                        ->get()
                                        ->map(fn(PatientDrug $pd) => $pd->drug->drugbank_id)
                                        ->unique();
        $count = $drugIds->count();
        file_put_contents($file, $drugIds->join("\n") . ($count > 0 ? "\n" : ""));

        return $file;
    }

}