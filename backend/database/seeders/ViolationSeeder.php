<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Violation;

class ViolationSeeder extends Seeder
{
    public function run(): void
    {
        $violations = [

            // =========================
            // A) TRICYCLE RELATED
            // Ord. No. 16-1067 Art. 7 Sec. 214
            // =========================
            [
                'type' => 'TRICYCLE_RELATED',
                'name' => 'Colourum Operation',
                'fine' => 5000.00,
                'ordinance_no' => 'Ord. No. 16-1067 Art. 7 Sec. 214',
            ],
            [
                'type' => 'TRICYCLE_RELATED',
                'name' => 'Driver',
                'fine' => 1000.00,
                'ordinance_no' => 'Ord. No. 16-1067 Art. 7 Sec. 214',
            ],
            [
                'type' => 'TRICYCLE_RELATED',
                'name' => "Failure to display Permit/Franchise, Tariffa and/or Driver's ID",
                'fine' => 100.00,
                'ordinance_no' => 'Ord. No. 16-1067 Art. 7 Sec. 214',
            ],
            [
                'type' => 'TRICYCLE_RELATED',
                'name' => 'Overcharging',
                'fine' => 600.00,
                'ordinance_no' => 'Ord. No. 16-1067 Art. 7 Sec. 214',
            ],
            [
                'type' => 'TRICYCLE_RELATED',
                'name' => 'Refusal to convey passenger',
                'fine' => 600.00,
                'ordinance_no' => 'Ord. No. 16-1067 Art. 7 Sec. 214',
            ],
            [
                'type' => 'TRICYCLE_RELATED',
                'name' => "No Driver's License",
                'fine' => 100.00,
                'ordinance_no' => 'Ord. No. 16-1067 Art. 7 Sec. 214',
            ],
            [
                'type' => 'TRICYCLE_RELATED',
                'name' => "No Driver's ID",
                'fine' => 300.00,
                'ordinance_no' => 'Ord. No. 16-1067 Art. 7 Sec. 214',
            ],
            [
                'type' => 'TRICYCLE_RELATED',
                'name' => 'Use of Fake / Unauthorized Driver\'s ID',
                'fine' => 300.00,
                'ordinance_no' => 'Ord. No. 16-1067 Art. 7 Sec. 214',
            ],
            [
                'type' => 'TRICYCLE_RELATED',
                'name' => 'Unauthorized Parking',
                'fine' => 200.00,
                'ordinance_no' => 'Ord. No. 16-1067 Art. 7 Sec. 214',
            ],
            [
                'type' => 'TRICYCLE_RELATED',
                'name' => 'Wearing of Shorts',
                'fine' => 2000.00,
                'ordinance_no' => 'Ord. No. 16-1120 Sec. 8-D',
            ],
            [
                'type' => 'TRICYCLE_RELATED',
                'name' => 'Reckless / Arrogant Driving',
                'fine' => 1000.00,
                'ordinance_no' => 'Ord. No. 16-1067 Art. 7 Sec. 214',
            ],
            [
                'type' => 'TRICYCLE_RELATED',
                'name' => 'No Permit',
                'fine' => 1000.00, // but not to exceed 5,000.00
                'ordinance_no' => 'Ord. No. 16-1067 Art. 7 Sec. 214',
            ],

            // =========================
            // B) OTHER MOTOR VEHICLE
            // =========================
            [
                'type' => 'OTHER_MOTOR_VEHICLE',
                'name' => 'Use of standard protective motorcycle helmet while driving and/or riding',
                'fine' => 250.00, // minimum; ticket notes "but not to exceed 2,000.00"
                'ordinance_no' => 'Ord. No. 1352',
            ],
            [
                'type' => 'OTHER_MOTOR_VEHICLE',
                'name' => 'Reckless Driving',
                'fine' => 1000.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'OTHER_MOTOR_VEHICLE',
                'name' => 'Speed Limit',
                'fine' => 1000.00,
                'ordinance_no' => 'Ord. No. 050-96',
            ],
            [
                'type' => 'OTHER_MOTOR_VEHICLE',
                'name' => 'Modified Muffler',
                'fine' => 150.00, // plus confiscation
                'ordinance_no' => 'Ord. No. 33-94',
            ],
            [
                'type' => 'OTHER_MOTOR_VEHICLE',
                'name' => 'Disregarding Traffic Sign',
                'fine' => 100.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'OTHER_MOTOR_VEHICLE',
                'name' => 'Illegal Parking',
                'fine' => 100.00,
                'ordinance_no' => 'Ord. No. 57 s. of 1964',
            ],
            [
                'type' => 'OTHER_MOTOR_VEHICLE',
                'name' => 'Use / Occupation of Public Road, Street, Sidewalk, Lanes and Alleys as Open Garage (Private and Public Vehicles)',
                'fine' => 1000.00,
                'ordinance_no' => 'Ord. No. 049-96',
            ],
            [
                'type' => 'OTHER_MOTOR_VEHICLE',
                'name' => 'Illegal / Unauthorized Terminal',
                'fine' => 1200.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'OTHER_MOTOR_VEHICLE',
                'name' => 'Broken Windshield',
                'fine' => 100.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'OTHER_MOTOR_VEHICLE',
                'name' => 'Incomplete Side Car No.',
                'fine' => 100.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'OTHER_MOTOR_VEHICLE',
                'name' => 'Unnecessary Lights',
                'fine' => 100.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'OTHER_MOTOR_VEHICLE',
                'name' => 'Out of Route Operation',
                'fine' => 300.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'OTHER_MOTOR_VEHICLE',
                'name' => 'No OR / CR',
                'fine' => 100.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'OTHER_MOTOR_VEHICLE',
                'name' => 'OR / CR Not Carried',
                'fine' => 100.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'OTHER_MOTOR_VEHICLE',
                'name' => 'Public Terminal Obstruction',
                'fine' => 100.00,
                'ordinance_no' => null,
            ],
        ];

        // Specific Violations requested by User
        $trafficViolations = [
            [
                'type' => 'TRAFFIC',
                'name' => 'Driving without license',
                'fine' => 3000.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'TRAFFIC',
                'name' => 'Not carrying license/OR/CR',
                'fine' => 1000.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'TRAFFIC',
                'name' => 'Reckless driving (1st offense)',
                'fine' => 2000.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'TRAFFIC',
                'name' => 'Reckless driving (2nd offense)',
                'fine' => 3000.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'TRAFFIC',
                'name' => 'Reckless driving (3rd offense+)',
                'fine' => 10000.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'TRAFFIC',
                'name' => 'No seatbelt (1st offense)',
                'fine' => 1000.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'TRAFFIC',
                'name' => 'No helmet (motorcycle, 1st offense)',
                'fine' => 1500.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'TRAFFIC',
                'name' => 'Disregarding traffic signs (DTS)',
                'fine' => 1000.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'TRAFFIC',
                'name' => 'Illegal parking (attended, MMDA)',
                'fine' => 1000.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'TRAFFIC',
                'name' => 'Illegal parking (unattended, MMDA)',
                'fine' => 2000.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'TRAFFIC',
                'name' => 'Number coding violation (UVVRP, MMDA)',
                'fine' => 500.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'TRAFFIC',
                'name' => 'Unregistered vehicle',
                'fine' => 10000.00,
                'ordinance_no' => null,
            ],
            [
                'type' => 'TRAFFIC',
                'name' => 'Defective / unauthorized accessories (sirens, blinkers, etc.)',
                'fine' => 5000.00,
                'ordinance_no' => null,
            ],
        ];

        $violations = array_merge($violations, $trafficViolations);

        foreach ($violations as $data) {
            Violation::updateOrCreate(
                [
                    'type' => $data['type'],
                    'name' => $data['name'],
                ],
                $data
            );
        }
    }
}
