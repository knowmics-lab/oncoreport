<?php

namespace App\Http\Services;

use App\Actions\Fortify\CreateNewUser as CreateUserAction;
use App\Models\Patient;
use App\Models\PatientDisease;
use App\Models\PatientDrug;
use App\Traits\UseNullableValues;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use JetBrains\PhpStorm\Pure;

class PatientHelperService
{

    use UseNullableValues;

    public function createOrUpdateDrug(Patient $patient, array $drug): PatientDrug
    {
        $id = $this->nullableId($drug['id'] ?? null);
        $update = (int)$id > 0;
        $patientDrug = ($update) ? $patient->drugs()->findOrFail($id) : null;
        $oldData = optional($patientDrug)->toArray() ?? [];
        $data = [
            'drug_id'            => (int)$this->old('drug', $drug, $oldData, $update, 'drug_id'),
            'patient_disease_id' => $this->nullableId(
                $this->old('disease', $drug, $oldData, $update, 'patient_disease_id')
            ),
            'comment'            => $this->nullableValue($this->old('comment', $drug, $oldData, $update)),
            'start_date'         => $this->dateOrNowIfEmpty($this->old('start_date', $drug, $oldData, $update)),
            'end_date'           => $this->nullableDate($this->old('end_date', $drug, $oldData, $update)),
        ];
        if ($update) {
            $patientDrug->update($data);
        } else {
            $patientDrug = $patient->drugs()->create($data);
        }
        if (isset($drug['suspension_reasons']) && is_array($drug['suspension_reasons'])) {
            $patientDrug->suspensionReasons()->sync($drug['suspension_reasons']);
        }

        return $patientDrug;
    }

    /**
     * @throws \Throwable
     */
    public function createPatient(array $values, ?int $ownerId): Patient
    {
        DB::beginTransaction();
        $patient = Patient::create(
            [
                'code'               => $values['code'],
                'first_name'         => $values['first_name'],
                'last_name'          => $values['last_name'],
                'gender'             => $values['gender'],
                'age'                => $values['age'],
                'email'              => $values['email'] ?? null,
                'fiscal_number'      => $values['fiscal_number'] ?? null,
                'telephone'          => $values['telephone'] ?? null,
                'city'               => $values['city'] ?? null,
                'user_id'            => null,
                'owner_id'           => $ownerId,
                'primary_disease_id' => null,
            ]
        );
        $primaryDisease = $this->createOrUpdateDisease($patient, $values['primary_disease']);
        $diseasesIdList = [$primaryDisease->id];
        if (isset($values['diseases']) && is_array($values['diseases'])) {
            foreach ($values['diseases'] as $disease) {
                $diseasesIdList[] = $this->createOrUpdateDisease($patient, $disease)->id;
            }
        }
        if (isset($values['drugs']) && is_array($values['drugs'])) {
            foreach ($values['drugs'] as $drug) {
                $this->internalCreateOrUpdateDrug($patient, $drug, $diseasesIdList);
            }
        }
        $userId = $this->createAccount($patient, $values);
        $patient->update(
            [
                'primary_disease_id' => $primaryDisease->id,
                'user_id'            => $userId,
            ]
        );
        DB::commit();

        return $patient;
    }

    public function createOrUpdateDisease(Patient $patient, array $disease): PatientDisease
    {
        $id = $this->nullableId($disease['id'] ?? null);
        $update = (int)$id > 0;
        $patientDisease = ($update) ? $patient->diseases()->findOrFail($id) : null;
        $oldData = optional($patientDisease)->toArray() ?? [];
        $data = [
            'disease_id'  => (int)$this->old('disease', $disease, $oldData, $update, 'disease_id'),
            'location_id' => $this->nullableId($this->old('location', $disease, $oldData, $update, 'location_id')),
            'type'        => $this->nullableValue($this->old('type', $disease, $oldData, $update)),
            'T'           => $this->nullableValue($this->old('T', $disease, $oldData, $update)),
            'N'           => $this->nullableValue($this->old('N', $disease, $oldData, $update)),
            'M'           => $this->nullableValue($this->old('M', $disease, $oldData, $update)),
            'start_date'  => $this->dateOrNowIfEmpty($this->old('start_date', $disease, $oldData, $update)),
            'end_date'    => $this->nullableDate($this->old('end_date', $disease, $oldData, $update)),
        ];
        if ($update) {
            $patientDisease->update($data);
        } else {
            $patientDisease = $patient->diseases()->create($data);
        }

        return $patientDisease;
    }

    private function internalCreateOrUpdateDrug(
        Patient $patient,
        array $drug,
        array $diseasesIdList,
        bool $isUpdatingPatient = false
    ): PatientDrug {
        $id = $this->nullableId($drug['id'] ?? null);
        $update = (int)$id > 0;
        $patientDrug = ($update) ? $patient->drugs()->findOrFail($id) : null;
        $oldData = optional($patientDrug)->toArray() ?? [];
        $data = [
            'drug_id'            => (int)$this->old('drug', $drug, $oldData, $update, 'drug_id'),
            'patient_disease_id' => $this->processDiseaseId(
                $patient->id,
                $oldData,
                $drug,
                $update,
                $diseasesIdList,
                $isUpdatingPatient
            ),
            'comment'            => $this->nullableValue($this->old('comment', $drug, $oldData, $update)),
            'start_date'         => $this->dateOrNowIfEmpty($this->old('start_date', $drug, $oldData, $update)),
            'end_date'           => $this->nullableDate($this->old('end_date', $drug, $oldData, $update)),
        ];
        if ($update) {
            $patientDrug->update($data);
        } else {
            $patientDrug = $patient->drugs()->create($data);
        }
        if (isset($drug['suspension_reasons']) && is_array($drug['suspension_reasons'])) {
            $patientDrug->suspensionReasons()->sync($drug['suspension_reasons']);
        }

        return $patientDrug;
    }

    #[Pure] protected function processDiseaseId(
        int $patientId,
        array $oldData,
        array $drug,
        bool $isUpdatingDisease,
        array $diseasesIdList,
        bool $isUpdatingPatient
    ): ?int {
        $diseaseId = $this->old('disease', $drug, $oldData, $isUpdatingDisease, 'patient_disease_id');
        if (is_null($diseaseId)) {
            return null;
        }
        if ($isUpdatingPatient && $diseaseId > 0) {
            if (!PatientDisease::where('patient_id', $patientId)->where('id', $diseaseId)->exists()) {
                throw ValidationException::withMessages([
                    'patient_disease_id' => 'Invalid patient disease id',
                ]);
            }

            return $diseaseId;
        }
        $diseaseId = abs($diseaseId);

        return $diseasesIdList[$diseaseId] ?? null;
    }

    public function createAccount(Patient $patient, array $values): ?int
    {
        $id = null;
        if ($values['create_account'] ?? false) {
            $user = (new CreateUserAction())->create(
                [
                    'name'     => $patient->full_name,
                    'email'    => $values['email'],
                    'password' => $values['password'],
                ]
            );
            $user->update(['email_verified_at' => now()]);
            $id = $user->id;
        }

        return $id;
    }

    /**
     * @throws \Throwable
     */
    public function updatePatient(Patient $patient, array $values): Patient
    {
        DB::beginTransaction();
        $this->updateAccount($patient, $values);
        $oldData = $patient->toArray();
        $primaryDiseaseId = $patient->primary_disease_id;
        if (isset($values['primary_disease'])) {
            $primaryDisease = $this->createOrUpdateDisease($patient, $values['primary_disease']);
            if ($primaryDisease->id !== $primaryDiseaseId) {
                $primaryDiseaseId = $primaryDisease->id;
            }
        }
        $diseasesIdList = [$primaryDiseaseId];
        if (isset($values['diseases']) && is_array($values['diseases'])) {
            foreach ($values['diseases'] as $disease) {
                $disease = $this->createOrUpdateDisease($patient, $disease);
                if ($disease->wasRecentlyCreated) {
                    $diseasesIdList[] = $disease->id;
                }
            }
        }
        if (isset($values['drugs']) && is_array($values['drugs'])) {
            foreach ($values['drugs'] as $drug) {
                $this->internalCreateOrUpdateDrug($patient, $drug, $diseasesIdList, true);
            }
        }
        $this->deleteDiseases($patient, $values);
        $this->deleteDrugs($patient, $values);
        $patient->update(
            [
                'code'               => $this->old('code', $values, $oldData),
                'first_name'         => $this->old('first_name', $values, $oldData),
                'last_name'          => $this->old('last_name', $values, $oldData),
                'gender'             => $this->old('gender', $values, $oldData),
                'age'                => $this->old('age', $values, $oldData),
                'email'              => $this->old('email', $values, $oldData),
                'fiscal_number'      => $this->old('fiscal_number', $values, $oldData),
                'telephone'          => $this->old('telephone', $values, $oldData),
                'city'               => $this->old('city', $values, $oldData),
                'primary_disease_id' => $primaryDiseaseId,
            ]
        );
        DB::commit();

        return $patient;
    }

    public function updateAccount(Patient $patient, array $values): void
    {
        if (isset($values['email']) && $patient->email !== $values['email'] && $patient->user_id) {
            $patient->user->update(['email' => $values['email']]);
        }
    }

    public function deleteDiseases(Patient $patient, array $values): void
    {
        if (isset($values['deleted_diseases'])
            && is_array($values['deleted_diseases'])
            && !empty($values['deleted_diseases'])) {
            $patient->diseases()->whereIn('id', $values['deleted_diseases'])->delete();
        }
    }

    public function deleteDrugs(Patient $patient, array $values): void
    {
        if (isset($values['deleted_drugs']) && is_array($values['deleted_drugs']) && !empty($values['deleted_drugs'])) {
            $patient->diseases()->whereIn('id', $values['deleted_drugs'])->delete();
        }
    }

}