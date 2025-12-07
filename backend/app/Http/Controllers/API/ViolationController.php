<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Violation;
use Illuminate\Http\Request;

class ViolationController extends Controller
{
    /**
     * GET /api/violation-types
     */
    public function types()
    {
        $types = Violation::query()
            ->select('type')
            ->distinct()
            ->orderBy('type')
            ->pluck('type');

        return response()->json($types);
    }

    /**
     * Generic listing used by BOTH enforcer & admin.
     *
     * - /api/violations              (public or protected, depending on your route group)
     * - /api/admin/violations        (behind auth:sanctum)
     *
     * Optional query params:
     *   ?type=TRICYCLE_RELATED
     *   ?q=colorum
     */
    public function index(Request $request)
    {
        $q    = trim((string) $request->query('q', ''));
        $type = trim((string) $request->query('type', ''));

        $query = Violation::query();

        if ($type !== '') {
            $query->where('type', $type);
        }

        if ($q !== '') {
            $query->where(function ($sub) use ($q) {
                $sub->where('name', 'like', "%{$q}%")
                    ->orWhere('ordinance_no', 'like', "%{$q}%");
            });
        }

        $violations = $query
            ->orderBy('type')
            ->orderBy('name')
            ->get([
                'id',
                'type',
                'name',
                'fine',
                'ordinance_no',
                'created_at',
                'updated_at',
            ]);

        return response()->json($violations);
    }

    /**
     * Admin list just reuses index() so logic is only in one place.
     * GET /api/admin/violations
     */
    public function adminIndex(Request $request)
    {
        return $this->index($request);
    }

    /**
     * POST /api/admin/violations
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'type'         => 'required|string|max:255',
            'name'         => 'required|string|max:255',
            'fine'         => 'required|numeric|min:0',
            'ordinance_no' => 'nullable|string|max:255',
        ]);

        $violation = Violation::create($data);

        return response()->json($violation, 201);
    }

    /**
     * PUT/PATCH /api/admin/violations/{violation}
     */
    public function update(Request $request, Violation $violation)
    {
        $data = $request->validate([
            'type'         => 'required|string|max:255',
            'name'         => 'required|string|max:255',
            'fine'         => 'required|numeric|min:0',
            'ordinance_no' => 'nullable|string|max:255',
        ]);

        $violation->update($data);

        return response()->json($violation);
    }
}
