<?php

namespace App\Http\Services;

use App\Actions\Fortify\CreateNewUser as CreateUserAction;
use App\Models\Patient;
use App\Models\PatientDisease;
use App\Utils;

class PatientHelperService
{

    public function createOrUpdateDisease(Patient $patient, array $disease): PatientDisease
    {
        $id = Utils::nullableId($disease['id'] ?? null);
        $data = [
            'disease_id'  => (int)$disease['disease'],
            'location_id' => Utils::nullableId($disease['location'] ?? null),
            'type'        => Utils::nullableValue($disease['type'] ?? null),
            'T'           => Utils::nullableValue($disease['T'] ?? null),
            'N'           => Utils::nullableValue($disease['N'] ?? null),
            'M'           => Utils::nullableValue($disease['M'] ?? null),
            'start_date'  => Utils::dateOrNowIfEmpty($disease['start_date'] ?? null),
            'end_date'    => Utils::nullableDate($disease['end_date'] ?? null),
        ];
        if ($id === null) {
            $patientDisease = $patient->diseases()->create($data);
        } else {
            $patientDisease = $patient->diseases()->findOrFail($id);
            $patientDisease->update($data);
        }

        return $patientDisease;
    }

    public function createOrUpdateDrug(Patient $patient, array $drug): void
    {
        $id = Utils::nullableId($drug['id'] ?? null);
        $data = [
            'drug_id'    => (int)$drug['drug'],
            'disease_id' => Utils::nullableId($drug['disease'] ?? null),
            'comment'    => Utils::nullableValue($drug['comment'] ?? null),
            'start_date' => Utils::dateOrNowIfEmpty($drug['start_date'] ?? null),
            'end_date'   => Utils::nullableDate($drug['end_date'] ?? null),
        ];
        if ($id === null) {
            $drugModel = $patient->drugs()->create($data);
        } else {
            $drugModel = $patient->drugs()->findOrFail($id);
            $drugModel->update($data);
        }
        if (isset($drug['suspension_reasons']) && is_array($drug['suspension_reasons'])) {
            $drugModel->suspensionReasons()->sync($drug['suspension_reasons']);
        }
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

    public function createPatient(array $values, ?int $ownerId): Patient
    {
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
        if (isset($values['diseases']) && is_array($values['diseases'])) {
            foreach ($values['diseases'] as $disease) {
                $this->createOrUpdateDisease($patient, $disease);
            }
        }
        if (isset($values['drugs']) && is_array($values['drugs'])) {
            foreach ($values['drugs'] as $drug) {
                $this->createOrUpdateDrug($patient, $drug);
            }
        }
        $userId = $this->createAccount($patient, $values);
        $patient->update(
            [
                'primary_disease_id' => $primaryDisease->id,
                'user_id'            => $userId,
            ]
        );
        $patient->load(['primaryDisease', 'diseases', 'drugs']);

        return $patient;
    }

}