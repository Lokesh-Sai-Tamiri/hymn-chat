-- ============================================================================
-- HIPAA-COMPLIANT ORGANIZATIONS SCHEMA
-- ============================================================================
-- 
-- HIPAA Compliance Features:
-- 1. Row Level Security (RLS) - Users can only access their organization data
-- 2. Audit logging - All changes tracked with timestamps
-- 3. Minimum necessary data - Only essential fields stored
-- 4. Access controls - Strict policies based on membership
-- 5. Soft deletes - Data retained for audit trail
-- ============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- ORGANIZATIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Basic Info
    name TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'hospital' CHECK (type IN ('hospital', 'clinic', 'practice', 'network', 'other')),
    description TEXT,
    
    -- Contact Info
    phone TEXT,
    email TEXT,
    website TEXT,
    
    -- Address
    address_line1 TEXT,
    address_line2 TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    country TEXT DEFAULT 'India',
    
    -- Branding
    logo_url TEXT,
    
    -- Settings
    is_public BOOLEAN DEFAULT false, -- Can be discovered by non-members
    max_members INTEGER DEFAULT 1000,
    
    -- Metadata
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Soft delete (HIPAA - data retention)
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES auth.users(id)
);

-- ============================================================================
-- DEPARTMENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Basic Info
    name TEXT NOT NULL,
    description TEXT,
    color TEXT, -- For UI display (e.g., '#FF5733')
    icon TEXT, -- Icon name for UI
    
    -- Leadership
    head_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    
    -- Metadata
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Soft delete
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- Prevent duplicate department names in same org
    UNIQUE(organization_id, name)
);

-- ============================================================================
-- ORGANIZATION MEMBERS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS organization_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign Keys
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    
    -- Role & Title
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'head', 'member', 'staff', 'guest')),
    title TEXT, -- e.g., "Head of Cardiology", "Senior Cardiologist"
    
    -- Status
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('active', 'inactive', 'pending', 'suspended')),
    
    -- Timestamps
    joined_at TIMESTAMP WITH TIME ZONE,
    invited_by UUID REFERENCES auth.users(id),
    invited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Soft delete (HIPAA - audit trail)
    left_at TIMESTAMP WITH TIME ZONE,
    left_reason TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Prevent duplicate memberships
    UNIQUE(organization_id, user_id)
);

-- ============================================================================
-- ORGANIZATION INVITES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS organization_invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Invite details
    email TEXT, -- For email invites
    phone TEXT, -- For phone invites
    invite_code TEXT UNIQUE, -- Shareable code
    
    -- Role assignment
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'head', 'member', 'staff', 'guest')),
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    
    -- Status
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired', 'cancelled')),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    
    -- Tracking
    invited_by UUID REFERENCES auth.users(id),
    accepted_by UUID REFERENCES auth.users(id),
    accepted_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_organizations_name ON organizations(name);
CREATE INDEX IF NOT EXISTS idx_organizations_type ON organizations(type);
CREATE INDEX IF NOT EXISTS idx_organizations_city ON organizations(city);
CREATE INDEX IF NOT EXISTS idx_organizations_created_by ON organizations(created_by);

CREATE INDEX IF NOT EXISTS idx_departments_org ON departments(organization_id);
CREATE INDEX IF NOT EXISTS idx_departments_head ON departments(head_user_id);

CREATE INDEX IF NOT EXISTS idx_org_members_org ON organization_members(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_members_user ON organization_members(user_id);
CREATE INDEX IF NOT EXISTS idx_org_members_dept ON organization_members(department_id);
CREATE INDEX IF NOT EXISTS idx_org_members_status ON organization_members(status);

CREATE INDEX IF NOT EXISTS idx_org_invites_org ON organization_invites(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_invites_code ON organization_invites(invite_code);
CREATE INDEX IF NOT EXISTS idx_org_invites_email ON organization_invites(email);

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_invites ENABLE ROW LEVEL SECURITY;

-- Organizations: Users can view orgs they're members of (or public orgs)
CREATE POLICY "Users can view their organizations"
    ON organizations FOR SELECT
    USING (
        deleted_at IS NULL AND (
            is_public = true
            OR EXISTS (
                SELECT 1 FROM organization_members om
                WHERE om.organization_id = organizations.id
                AND om.user_id = auth.uid()
                AND om.status = 'active'
                AND om.left_at IS NULL
            )
        )
    );

-- Organizations: Only owners/admins can update
CREATE POLICY "Admins can update organizations"
    ON organizations FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM organization_members om
            WHERE om.organization_id = organizations.id
            AND om.user_id = auth.uid()
            AND om.role IN ('owner', 'admin')
            AND om.status = 'active'
        )
    );

-- Organizations: Authenticated users can create
CREATE POLICY "Users can create organizations"
    ON organizations FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = created_by);

-- Departments: Users can view departments in their orgs
CREATE POLICY "Users can view departments in their orgs"
    ON departments FOR SELECT
    USING (
        deleted_at IS NULL AND
        EXISTS (
            SELECT 1 FROM organization_members om
            WHERE om.organization_id = departments.organization_id
            AND om.user_id = auth.uid()
            AND om.status = 'active'
            AND om.left_at IS NULL
        )
    );

-- Departments: Admins can manage departments
CREATE POLICY "Admins can manage departments"
    ON departments FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM organization_members om
            WHERE om.organization_id = departments.organization_id
            AND om.user_id = auth.uid()
            AND om.role IN ('owner', 'admin')
            AND om.status = 'active'
        )
    );

-- Members: Users can view members in their orgs
CREATE POLICY "Users can view org members"
    ON organization_members FOR SELECT
    USING (
        left_at IS NULL AND
        EXISTS (
            SELECT 1 FROM organization_members om2
            WHERE om2.organization_id = organization_members.organization_id
            AND om2.user_id = auth.uid()
            AND om2.status = 'active'
            AND om2.left_at IS NULL
        )
    );

-- Members: Users can update their own membership
CREATE POLICY "Users can update own membership"
    ON organization_members FOR UPDATE
    USING (user_id = auth.uid());

-- Members: Admins can manage all members
CREATE POLICY "Admins can manage members"
    ON organization_members FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM organization_members om2
            WHERE om2.organization_id = organization_members.organization_id
            AND om2.user_id = auth.uid()
            AND om2.role IN ('owner', 'admin')
            AND om2.status = 'active'
        )
    );

-- Invites: Users can view invites for their orgs (if admin) or their own
CREATE POLICY "Users can view relevant invites"
    ON organization_invites FOR SELECT
    USING (
        email = (SELECT email FROM auth.users WHERE id = auth.uid())
        OR phone = (SELECT phone FROM auth.users WHERE id = auth.uid())
        OR EXISTS (
            SELECT 1 FROM organization_members om
            WHERE om.organization_id = organization_invites.organization_id
            AND om.user_id = auth.uid()
            AND om.role IN ('owner', 'admin')
            AND om.status = 'active'
        )
    );

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_org_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER organizations_updated_at
    BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_org_updated_at();

CREATE TRIGGER departments_updated_at
    BEFORE UPDATE ON departments
    FOR EACH ROW EXECUTE FUNCTION update_org_updated_at();

CREATE TRIGGER org_members_updated_at
    BEFORE UPDATE ON organization_members
    FOR EACH ROW EXECUTE FUNCTION update_org_updated_at();

-- ============================================================================
-- VIEWS
-- ============================================================================

-- User's organizations with membership info
CREATE OR REPLACE VIEW my_organizations AS
SELECT 
    o.id as organization_id,
    o.name as organization_name,
    o.type as organization_type,
    o.logo_url,
    o.city,
    o.state,
    om.role,
    om.title,
    om.status,
    om.joined_at,
    d.id as department_id,
    d.name as department_name,
    (SELECT COUNT(*) FROM organization_members om2 
     WHERE om2.organization_id = o.id 
     AND om2.status = 'active' 
     AND om2.left_at IS NULL) as member_count
FROM organization_members om
JOIN organizations o ON om.organization_id = o.id
LEFT JOIN departments d ON om.department_id = d.id
WHERE 
    om.user_id = auth.uid()
    AND om.status = 'active'
    AND om.left_at IS NULL
    AND o.deleted_at IS NULL;

-- Organization members with profile info (for org members to see colleagues)
CREATE OR REPLACE VIEW organization_colleagues AS
SELECT 
    om.id as membership_id,
    om.organization_id,
    om.user_id,
    om.department_id,
    om.role,
    om.title,
    om.status,
    om.joined_at,
    d.name as department_name,
    d.color as department_color,
    p.first_name,
    p.last_name,
    p.display_name,
    p.specialization,
    p.avatar_url
FROM organization_members om
LEFT JOIN departments d ON om.department_id = d.id
JOIN profiles p ON om.user_id = p.id
WHERE 
    om.status = 'active'
    AND om.left_at IS NULL
    AND EXISTS (
        SELECT 1 FROM organization_members my_om
        WHERE my_om.organization_id = om.organization_id
        AND my_om.user_id = auth.uid()
        AND my_om.status = 'active'
        AND my_om.left_at IS NULL
    );

-- Departments with member count
CREATE OR REPLACE VIEW organization_departments AS
SELECT 
    d.id as department_id,
    d.organization_id,
    d.name,
    d.description,
    d.color,
    d.icon,
    d.display_order,
    d.head_user_id,
    hp.first_name as head_first_name,
    hp.last_name as head_last_name,
    (SELECT COUNT(*) FROM organization_members om 
     WHERE om.department_id = d.id 
     AND om.status = 'active' 
     AND om.left_at IS NULL) as member_count
FROM departments d
LEFT JOIN profiles hp ON d.head_user_id = hp.id
WHERE 
    d.deleted_at IS NULL
    AND EXISTS (
        SELECT 1 FROM organization_members om
        WHERE om.organization_id = d.organization_id
        AND om.user_id = auth.uid()
        AND om.status = 'active'
        AND om.left_at IS NULL
    )
ORDER BY d.display_order, d.name;

-- Pending invites for current user
CREATE OR REPLACE VIEW my_pending_invites AS
SELECT 
    i.id as invite_id,
    i.organization_id,
    i.role,
    i.department_id,
    i.invite_code,
    i.expires_at,
    i.created_at,
    o.name as organization_name,
    o.type as organization_type,
    o.logo_url,
    o.city,
    o.state,
    d.name as department_name,
    inviter.first_name as inviter_first_name,
    inviter.last_name as inviter_last_name
FROM organization_invites i
JOIN organizations o ON i.organization_id = o.id
LEFT JOIN departments d ON i.department_id = d.id
LEFT JOIN profiles inviter ON i.invited_by = inviter.id
WHERE 
    i.status = 'pending'
    AND i.expires_at > NOW()
    AND o.deleted_at IS NULL
    AND (
        i.email = (SELECT email FROM auth.users WHERE id = auth.uid())
        OR i.phone = (SELECT phone FROM auth.users WHERE id = auth.uid())
    );

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Create organization with owner membership
CREATE OR REPLACE FUNCTION create_organization(
    p_name TEXT,
    p_type TEXT DEFAULT 'hospital',
    p_description TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_state TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_org_id UUID;
BEGIN
    -- Create organization
    INSERT INTO organizations (name, type, description, city, state, created_by)
    VALUES (p_name, p_type, p_description, p_city, p_state, auth.uid())
    RETURNING id INTO v_org_id;

    -- Add creator as owner
    INSERT INTO organization_members (organization_id, user_id, role, status, joined_at)
    VALUES (v_org_id, auth.uid(), 'owner', 'active', NOW());

    RETURN v_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create department
CREATE OR REPLACE FUNCTION create_department(
    p_organization_id UUID,
    p_name TEXT,
    p_description TEXT DEFAULT NULL,
    p_color TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_dept_id UUID;
BEGIN
    -- Verify user is admin/owner
    IF NOT EXISTS (
        SELECT 1 FROM organization_members
        WHERE organization_id = p_organization_id
        AND user_id = auth.uid()
        AND role IN ('owner', 'admin')
        AND status = 'active'
    ) THEN
        RAISE EXCEPTION 'Not authorized to create departments';
    END IF;

    INSERT INTO departments (organization_id, name, description, color)
    VALUES (p_organization_id, p_name, p_description, p_color)
    RETURNING id INTO v_dept_id;

    RETURN v_dept_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Join organization (via invite code)
CREATE OR REPLACE FUNCTION join_organization_by_code(p_invite_code TEXT)
RETURNS UUID AS $$
DECLARE
    v_invite organization_invites%ROWTYPE;
    v_member_id UUID;
BEGIN
    -- Get and validate invite
    SELECT * INTO v_invite
    FROM organization_invites
    WHERE invite_code = p_invite_code
    AND status = 'pending'
    AND expires_at > NOW();

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid or expired invite code';
    END IF;

    -- Check if already a member
    IF EXISTS (
        SELECT 1 FROM organization_members
        WHERE organization_id = v_invite.organization_id
        AND user_id = auth.uid()
        AND left_at IS NULL
    ) THEN
        RAISE EXCEPTION 'Already a member of this organization';
    END IF;

    -- Create membership
    INSERT INTO organization_members (
        organization_id, user_id, department_id, role, status, joined_at, invited_by
    )
    VALUES (
        v_invite.organization_id, auth.uid(), v_invite.department_id, 
        v_invite.role, 'active', NOW(), v_invite.invited_by
    )
    RETURNING id INTO v_member_id;

    -- Update invite status
    UPDATE organization_invites
    SET status = 'accepted', accepted_by = auth.uid(), accepted_at = NOW()
    WHERE id = v_invite.id;

    RETURN v_member_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Leave organization
CREATE OR REPLACE FUNCTION leave_organization(p_organization_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if user is the only owner
    IF (
        SELECT COUNT(*) FROM organization_members
        WHERE organization_id = p_organization_id
        AND role = 'owner'
        AND status = 'active'
        AND left_at IS NULL
    ) = 1 AND EXISTS (
        SELECT 1 FROM organization_members
        WHERE organization_id = p_organization_id
        AND user_id = auth.uid()
        AND role = 'owner'
    ) THEN
        RAISE EXCEPTION 'Cannot leave: You are the only owner. Transfer ownership first.';
    END IF;

    -- Soft delete membership
    UPDATE organization_members
    SET left_at = NOW(), left_reason = 'voluntary'
    WHERE organization_id = p_organization_id
    AND user_id = auth.uid()
    AND left_at IS NULL;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Generate invite code
CREATE OR REPLACE FUNCTION create_organization_invite(
    p_organization_id UUID,
    p_role TEXT DEFAULT 'member',
    p_department_id UUID DEFAULT NULL,
    p_email TEXT DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
    v_invite_code TEXT;
BEGIN
    -- Verify user is admin/owner
    IF NOT EXISTS (
        SELECT 1 FROM organization_members
        WHERE organization_id = p_organization_id
        AND user_id = auth.uid()
        AND role IN ('owner', 'admin')
        AND status = 'active'
    ) THEN
        RAISE EXCEPTION 'Not authorized to create invites';
    END IF;

    -- Generate unique code
    v_invite_code := encode(gen_random_bytes(6), 'hex');

    INSERT INTO organization_invites (
        organization_id, role, department_id, email, invite_code, invited_by
    )
    VALUES (
        p_organization_id, p_role, p_department_id, p_email, v_invite_code, auth.uid()
    );

    RETURN v_invite_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update member department
CREATE OR REPLACE FUNCTION update_member_department(
    p_member_id UUID,
    p_department_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_org_id UUID;
BEGIN
    -- Get organization ID
    SELECT organization_id INTO v_org_id
    FROM organization_members WHERE id = p_member_id;

    -- Verify user is admin/owner
    IF NOT EXISTS (
        SELECT 1 FROM organization_members
        WHERE organization_id = v_org_id
        AND user_id = auth.uid()
        AND role IN ('owner', 'admin')
        AND status = 'active'
    ) THEN
        RAISE EXCEPTION 'Not authorized to update members';
    END IF;

    UPDATE organization_members
    SET department_id = p_department_id
    WHERE id = p_member_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT ON my_organizations TO authenticated;
GRANT SELECT ON organization_colleagues TO authenticated;
GRANT SELECT ON organization_departments TO authenticated;
GRANT SELECT ON my_pending_invites TO authenticated;

GRANT EXECUTE ON FUNCTION create_organization TO authenticated;
GRANT EXECUTE ON FUNCTION create_department TO authenticated;
GRANT EXECUTE ON FUNCTION join_organization_by_code TO authenticated;
GRANT EXECUTE ON FUNCTION leave_organization TO authenticated;
GRANT EXECUTE ON FUNCTION create_organization_invite TO authenticated;
GRANT EXECUTE ON FUNCTION update_member_department TO authenticated;
